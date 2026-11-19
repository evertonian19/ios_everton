import Foundation
import EvCore

/// 프리미어리그 공식 사이트의 선수 사진 (개인 기기 열람용).
/// 비공개 API 는 쓰지 않는다: 브라우저가 받는 공개 선수단 HTML 에서 선수 ID 를 읽고, 사진은 공개 이미지 서버에서 불러온다.
/// 스토어 배포 등 공개 서비스로 낼 때는 `enabled` 를 false 로 바꿔 Commons 사진·이니셜만 쓰게 한다.
/// 구성: PLSquadParser(파싱·이름 매칭) · PLClubDirectory(구단 id 탐색) · PLPhotos(부착).
public enum PLPhotos {
    public static var enabled = true
    static let site = "https://www.premierleague.com"
    static let credit = PhotoCredit(author: "Premier League", license: "공식 사이트 이미지(개인 열람용)")

    static func imageURL(_ id: String) -> URL? {
        URL(string: "https://resources.premierleague.com/premierleague25/photos/players/110x140/\(id).png")
    }

    /// 선수들에게 PL 사진을 붙인다(Commons 보다 우선). `keep` 의 선수는 건드리지 않는다.
    static func attach(_ players: [Player], entries: [PLSquadParser.Entry], validate: @Sendable (String) async -> Bool,
                       keep: Set<Int> = []) async -> [Player] {
        var found: [Int: PLSquadParser.Entry] = [:]
        for p in players where !keep.contains(p.id) { if let e = PLSquadParser.match(p.name, entries) { found[p.id] = e } }
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
    /// 구단의 PL 선수단 HTML 을 24시간 캐시로 읽어 사진을 붙인다. 구단 연결이나 네트워크가 실패하면 받은 목록 그대로.
    func attachPLPhotos(_ players: [Player], clubID: Int, keep: Set<Int> = []) async -> [Player] {
        guard PLPhotos.enabled, let names = await espnNames(clubID: clubID) else { return players }
        let directory = PLClubDirectory(session: session, cache: cache)
        guard let plID = PLClubDirectory.clubID(for: names, in: await directory.clubs()),
              let url = URL(string: "\(PLPhotos.site)/en/clubs/\(plID)/x/squad") else { return players }
        let key = "pl_squad_\(plID)"
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
        let entries = PLSquadParser.parseSquad(html)
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

    func espnNames(clubID: Int) async -> [String]? {
        guard let info = try? await clubs().first(where: { $0.club.id == clubID }) else { return nil }
        return [info.club.name, info.club.shortName].compactMap { $0 }
    }
}
