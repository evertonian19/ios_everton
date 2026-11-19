import Foundation
import EvCore

/// 프리미어리그 공식 사이트의 선수 사진 (개인 기기 열람용).
/// 비공개 API 는 쓰지 않는다: 브라우저가 받는 공개 선수단 HTML 에서 선수 ID 를 읽고, 사진은 공개 이미지 서버에서 불러온다.
/// 스토어 배포 등 공개 서비스로 낼 때는 `enabled` 를 false 로 바꿔 Commons 사진·이니셜만 쓰게 한다.
public enum PLPhotos {
    public static var enabled = true
    /// ESPN 구단 id → (PL 구단 id, slug). 다른 구단은 매핑이 없어 사진을 붙이지 않는다.
    static let clubs: [Int: (id: Int, slug: String)] = [368: (11, "everton")]
    static let site = "https://www.premierleague.com"
    static let credit = PhotoCredit(author: "Premier League", license: "공식 사이트 이미지(개인 열람용)")

    struct Entry: Equatable { let id: String; let slug: String }

    static func imageURL(_ id: String) -> URL? {
        URL(string: "https://resources.premierleague.com/premierleague25/photos/players/110x140/\(id).png")
    }

    /// 선수단 HTML → 선수 목록(등장 순서, 중복 제거).
    static func parseSquad(_ html: String) -> [Entry] {
        guard let regex = try? NSRegularExpression(pattern: #"/en/players/(\d+)/([a-z0-9-]+)/overview"#) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        var seen = Set<String>()
        var out: [Entry] = []
        for m in regex.matches(in: html, range: range) {
            guard let idRange = Range(m.range(at: 1), in: html), let slugRange = Range(m.range(at: 2), in: html) else { continue }
            let id = String(html[idRange])
            if seen.insert(id).inserted { out.append(Entry(id: id, slug: String(html[slugRange]))) }
        }
        return out
    }

    /// 이름/slug 비교용 키: ASCII 알파벳만 남긴다 (Nørgaard·Röhl 은 slug 에서도 같은 글자가 빠진다).
    static func key(_ text: String) -> String {
        String(text.lowercased().unicodeScalars.filter { $0.value >= 97 && $0.value <= 122 }.map(Character.init))
    }

    static func match(_ name: String, _ entries: [Entry]) -> Entry? {
        let want = key(name)
        let hits = entries.filter { key($0.slug.replacingOccurrences(of: "-", with: " ")) == want }
        if hits.count == 1 { return hits[0] }
        if !hits.isEmpty { return nil }
        let parts = name.split(whereSeparator: { $0 == " " || $0 == "-" }).map(String.init)
        guard parts.count >= 2, let first = key(parts[0]).first else { return nil }
        let last = key(parts[parts.count - 1])
        let candidates = entries.filter { entry in
            let pieces = entry.slug.split(separator: "-")
            return pieces.last.map { key(String($0)) } == last && key(entry.slug).first == first
        }
        return candidates.count == 1 ? candidates[0] : nil
    }

    /// 선수들에게 PL 사진을 붙인다(Commons 보다 우선). `keep` 의 선수는 건드리지 않는다.
    static func attach(_ players: [Player], entries: [Entry], validate: @Sendable (String) async -> Bool,
                       keep: Set<Int> = []) async -> [Player] {
        var found: [Int: Entry] = [:]
        for p in players where !keep.contains(p.id) { if let e = match(p.name, entries) { found[p.id] = e } }
        var ok: [String: Bool] = [:]
        await withTaskGroup(of: (String, Bool).self) { group in
            for id in Set(found.values.map(\.id)) { group.addTask { (id, await validate(id)) } }
            for await (id, good) in group { ok[id] = good }
        }
        return players.map { p in
            guard let e = found[p.id], ok[e.id] == true, let url = imageURL(e.id) else { return p }
            var q = p
            q.photoURL = url
            q.photoCredit = PhotoCredit(author: credit.author, license: credit.license, licenseURL: nil,
                                        pageURL: URL(string: "\(site)/en/players/\(e.id)/\(e.slug)/overview"))
            return q
        }
    }
}

extension ESPNService {
    /// 에버턴 선수단 HTML 을 24시간 캐시로 읽어 사진을 붙인다. 실패하면 받은 선수 목록 그대로.
    func attachPLPhotos(_ players: [Player], clubID: Int, keep: Set<Int> = []) async -> [Player] {
        guard PLPhotos.enabled, let club = PLPhotos.clubs[clubID],
              let url = URL(string: "\(PLPhotos.site)/en/clubs/\(club.id)/\(club.slug)/squad") else { return players }
        let key = "pl_" + url.absoluteString
        var html: String?
        if let cached = await cache.data(for: key, maxAge: 86_400) { html = String(data: cached, encoding: .utf8) }
        if html == nil {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            if let (data, response) = try? await session.data(for: request),
               (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) == true {
                await cache.store(data, for: key)
                html = String(data: data, encoding: .utf8)
            } else if let stale = await cache.data(for: key, maxAge: nil) {
                html = String(data: stale, encoding: .utf8)
            }
        }
        guard let html else { return players }
        let entries = PLPhotos.parseSquad(html)
        guard !entries.isEmpty else { return players }
        let session = self.session
        return await PLPhotos.attach(players, entries: entries, validate: { id in
            guard let imageURL = PLPhotos.imageURL(id) else { return false }
            var head = URLRequest(url: imageURL)
            head.httpMethod = "HEAD"
            head.timeoutInterval = 10
            guard let (_, response) = try? await session.data(for: head), let http = response as? HTTPURLResponse else { return false }
            // 사진이 없는 선수는 약 6KB 자리표시 이미지가 온다 → 2만 바이트 이상일 때만 실제 사진으로 본다.
            return http.statusCode == 200 && http.expectedContentLength > 20_000
        }, keep: keep)
    }
}
