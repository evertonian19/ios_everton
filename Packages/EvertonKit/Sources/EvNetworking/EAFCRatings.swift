import Foundation
import EvCore

/// EA SPORTS FC 공식 평가(drop-api.ea.com, 키 불필요)를 이름 검색으로 받아 온다. 하루 디스크 캐시.
/// 선수 매칭은 (이름 일치 + 생년월일 일치)일 때만 인정하고, 애매하면 nil(평가 없음)이다 — 임의 값을 만들지 않는다.
public actor EAFCRatings {
    private let cache: DiskCache
    private let session: URLSession
    private let maxAge: TimeInterval = 24 * 3600

    public init(cache: DiskCache = DiskCache(), session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    private struct Response: Decodable { let items: [Item] }

    struct Item: Decodable {
        struct Named: Decodable { let label: String? ; let shortLabel: String? }
        struct Value: Decodable { let value: Int }
        struct Ability: Decodable { let label: String?; let description: String? }
        let id: Int
        let firstName: String?
        let lastName: String?
        let commonName: String?
        let birthdate: String?
        let overallRating: Int
        let preferredFoot: Int?
        let weakFootAbility: Int?
        let skillMoves: Int?
        let team: Named?
        let position: Named?
        let alternatePositions: [Named]?
        let stats: [String: Value]?
        let playerAbilities: [Ability]?
    }

    // MARK: 공개

    public func rating(for player: Player) async -> PlayerRatings? {
        let words = Self.normalize(player.name).split(separator: " ").map(String.init)
        guard let last = words.last else { return nil }
        var seen = Set<String>()
        for term in [last, words[0]] where seen.insert(term).inserted {
            guard let (items, at) = await search(term) else { continue }
            var hits = items.filter { Self.isMatch(player, $0) }
            if hits.count > 1 {
                hits = hits.filter { words.contains(Self.normalize($0.firstName ?? "")) || Self.normalize($0.commonName ?? "") == Self.normalize(player.name) }
            }
            if hits.count == 1, let item = hits.first { return Self.make(item, player: player, at: at) }
        }
        return nil
    }

    // MARK: 받기

    private func search(_ term: String) async -> ([Item], Date)? {
        let key = "eafc_" + term
        if let data = await cache.data(for: key, maxAge: maxAge), let items = try? JSONDecoder().decode(Response.self, from: data).items {
            return (items, await cache.savedAt(for: key) ?? Date())
        }
        var components = URLComponents(string: "https://drop-api.ea.com/rating/ea-sports-fc")!
        components.queryItems = [.init(name: "locale", value: "en"), .init(name: "limit", value: "50"), .init(name: "search", value: term)]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200, let items = try? JSONDecoder().decode(Response.self, from: data).items else { throw URLError(.badServerResponse) }
            await cache.store(data, for: key)
            return (items, Date())
        } catch {
            // 실패하면 만료된 캐시라도 쓴다(받은 날짜를 그대로 보여 주므로 속이지 않는다).
            if let data = await cache.data(for: key, maxAge: nil), let items = try? JSONDecoder().decode(Response.self, from: data).items { return (items, await cache.savedAt(for: key) ?? .distantPast) }
            return nil
        }
    }

    // MARK: 매칭

    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
        let map: [Character: String] = ["ø": "o", "đ": "d", "ł": "l", "æ": "ae", "ß": "ss", "ı": "i"]
        return folded.map { map[$0] ?? String($0) }.joined().replacingOccurrences(of: "-", with: " ").trimmingCharacters(in: .whitespaces)
    }

    private static let utc: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()

    static func born(_ text: String?) -> DateComponents? {
        guard let text else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "M/d/yyyy h:mm:ss a"
        guard let date = f.date(from: text) else { return nil }
        return utc.dateComponents([.year, .month, .day], from: date)
    }

    static func isMatch(_ player: Player, _ item: Item) -> Bool {
        let name = normalize(player.name)
        let last = normalize(item.lastName ?? "")
        let full = normalize([item.firstName, item.lastName].compactMap { $0 }.joined(separator: " "))
        let common = normalize(item.commonName ?? "")
        let lastOK = !last.isEmpty && (name.hasSuffix(last) || name.split(separator: " ").contains { String($0) == last } || (!common.isEmpty && name.contains(common)))
        if let birth = player.birthDate, let other = born(item.birthdate) {
            let mine = utc.dateComponents([.year, .month, .day], from: birth)
            if mine == other { return lastOK || name == full }
            // 시간대 때문에 하루 어긋나는 경우는 이름 전체가 같을 때만 인정.
            if let a = utc.date(from: mine), let b = utc.date(from: other),
               abs(utc.dateComponents([.day], from: a, to: b).day ?? 9) <= 1 { return name == full }
            return false
        }
        return name == full || (!common.isEmpty && name == common)
    }

    static func make(_ item: Item, player: Player, at: Date) -> PlayerRatings {
        let stats = (item.stats ?? [:]).mapValues(\.value)
        let abilities = (item.playerAbilities ?? []).compactMap { a -> PlayerRatings.Ability? in
            guard let label = a.label, let text = a.description else { return nil }
            return .init(label: label, description: text)
        }
        return PlayerRatings.make(
            eaID: item.id, overall: item.overallRating, stats: stats, isKeeper: player.position == .goalkeeper,
            position: item.position?.shortLabel ?? "", alternates: (item.alternatePositions ?? []).compactMap(\.shortLabel),
            foot: item.preferredFoot == 1 ? "right" : item.preferredFoot == 2 ? "left" : nil,
            weakFoot: item.weakFootAbility, skillMoves: item.skillMoves, abilities: abilities, team: item.team?.label,
            fetchedAt: at)
    }
}
