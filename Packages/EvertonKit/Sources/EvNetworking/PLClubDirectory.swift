import Foundation
import EvCore

/// ESPN 구단 ↔ 프리미어리그 구단 id 연결. PL 선수단 페이지는 slug 를 무시하고 id 만 보므로
/// id 1…80 을 천천히(직렬·간격·429 시 중단) 훑어 <title> 의 구단명으로 매핑하고 14일 캐시한다.
actor PLClubDirectory {
    static let aliases: [String: String] = [
        "wolves": "wolverhampton wanderers", "spurs": "tottenham hotspur", "brighton": "brighton and hove albion",
        "man utd": "manchester united", "man city": "manchester city", "newcastle": "newcastle united",
        "west ham": "west ham united", "leeds": "leeds united", "forest": "nottingham forest",
    ]
    /// 직접 확인한 값. 나머지는 탐색으로 채운다.
    static let seed: [Int: String] = [
        1: "Manchester United", 2: "Leeds United", 3: "Arsenal", 4: "Newcastle United", 6: "Tottenham Hotspur",
        7: "Aston Villa", 11: "Everton", 14: "Liverpool", 31: "Crystal Palace", 36: "Brighton and Hove Albion",
        39: "Wolverhampton Wanderers",
    ]
    static let maxID = 80
    static let ttl: TimeInterval = 14 * 86_400

    private let session: URLSession
    private let cache: DiskCache
    private var scanning = false
    private var cooldownUntil = Date.distantPast
    private let cacheKey = "pl_club_directory"

    private struct Stored: Codable { var clubs: [Int: String]; var next: Int; var at: Date? }

    init(session: URLSession, cache: DiskCache) {
        self.session = session
        self.cache = cache
    }

    /// 이름 정규화: 소문자·기호 제거·"&"→and·afc/fc/the 제거·별칭 치환.
    static func normalize(_ name: String) -> String {
        let cleaned = name.lowercased().replacingOccurrences(of: "&", with: " and ")
            .map { $0.isLetter || $0.isNumber || $0 == " " ? $0 : " " }
        let words = String(cleaned).split(separator: " ").map(String.init).filter { !["afc", "fc", "the"].contains($0) }
        let joined = words.joined(separator: " ")
        return aliases[joined] ?? joined
    }

    /// ESPN 구단명(들)과 정규화 이름이 정확히 일치하는 PL 구단 id. 유일하지 않으면 nil.
    static func clubID(for names: [String], in clubs: [Int: String]) -> Int? {
        let wanted = Set(names.map(normalize).filter { !$0.isEmpty })
        let hits = clubs.filter { wanted.contains(normalize($0.value)) }.map(\.key)
        return hits.count == 1 ? hits[0] : nil
    }

    /// 지금 알고 있는 매핑(시드+저장된 탐색 결과)을 즉시 돌려주고, 오래됐으면 백그라운드에서 이어서 탐색한다.
    func clubs() async -> [Int: String] {
        let stored = await load()
        var merged = Self.seed
        stored.clubs.forEach { merged[$0.key] = $0.value }
        let fresh = stored.at.map { Date().timeIntervalSince($0) < Self.ttl } ?? false
        if !fresh, !scanning, Date() >= cooldownUntil {
            scanning = true
            Task { await self.scan() }
        }
        return merged
    }

    private func load() async -> Stored {
        if let data = await cache.data(for: cacheKey, maxAge: nil), let s = try? JSONDecoder().decode(Stored.self, from: data) { return s }
        return Stored(clubs: [:], next: 1, at: nil)
    }

    private func save(_ s: Stored) async {
        if let data = try? JSONEncoder().encode(s) { await cache.store(data, for: cacheKey) }
    }

    private func scan() async {
        defer { scanning = false }
        var state = await load()
        if state.next > Self.maxID { state.next = 1 }
        while state.next <= Self.maxID {
            guard let url = URL(string: "\(PLPhotos.site)/en/clubs/\(state.next)/x/squad") else { return }
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            if let (data, response) = try? await session.data(for: request), let http = response as? HTTPURLResponse {
                if http.statusCode == 429 { cooldownUntil = Date().addingTimeInterval(600); await save(state); return }
                if http.statusCode == 200, let html = String(data: data, encoding: .utf8), let name = PLSquadParser.clubName(html) {
                    state.clubs[state.next] = name
                }
            }
            state.next += 1
            await save(state)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
        }
        state.at = Date()
        await save(state)
    }
}
