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

    /// {선수 id: PL 사진 후보(고해상도 250x250 → 저해상도 110x140)}. `keep`(수동 지정) 선수는 제외한다.
    /// 실제 다운로드·검증은 PhotoCache 가 한다.
    static func candidates(_ players: [Player], entries: [PLSquadParser.Entry], keep: Set<Int> = []) -> [Int: [PhotoCandidate]] {
        var out: [Int: [PhotoCandidate]] = [:]
        for p in players where !keep.contains(p.id) {
            guard let e = PLSquadParser.match(p.name, entries) else { continue }
            let credit = PhotoCredit(author: credit.author, license: credit.license, licenseURL: nil,
                                     pageURL: URL(string: "\(site)/en/players/\(e.id)/\(e.slug)/overview"))
            out[p.id] = [hiURL(e.id), imageURL(e.id)].compactMap { $0 }.map { PhotoCandidate(url: $0, source: .premierleague, credit: credit) }
        }
        return out
    }

    static func hiURL(_ id: String) -> URL? {
        URL(string: "https://resources.premierleague.com/premierleague/photos/players/250x250/p\(id).png")
    }
}

extension ESPNService {
    /// 구단의 PL 선수단 HTML(7일 캐시, 실패 시 오래된 캐시)에서 사진 후보를 만든다. 구단 연결이나 네트워크가 실패하면 빈 값.
    func plCandidates(_ players: [Player], clubID: Int, keep: Set<Int> = []) async -> [Int: [PhotoCandidate]] {
        guard PLPhotos.enabled, let names = await espnNames(clubID: clubID) else { return [:] }
        let directory = PLClubDirectory(session: session, cache: cache)
        guard let plID = PLClubDirectory.clubID(for: names, in: await directory.clubs()),
              let url = URL(string: "\(PLPhotos.site)/en/clubs/\(plID)/x/squad") else { return [:] }
        let key = "pl_squad_\(plID)"
        var html: String?
        if let cached = await cache.data(for: key, maxAge: 7 * 86_400) { html = String(data: cached, encoding: .utf8) }
        if html == nil, await directory.mayRequest() {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            if let (data, response) = try? await session.data(for: request), let http = response as? HTTPURLResponse {
                if http.statusCode == 429 { await directory.coolDown() }
                else if (200..<300).contains(http.statusCode) {
                    await cache.store(data, for: key)
                    html = String(data: data, encoding: .utf8)
                }
            }
            if html == nil, let stale = await cache.data(for: key, maxAge: nil) { html = String(data: stale, encoding: .utf8) }
        } else if html == nil, let stale = await cache.data(for: key, maxAge: nil) {
            html = String(data: stale, encoding: .utf8)
        }
        guard let html else { return [:] }
        let entries = PLSquadParser.parseSquad(html)
        return entries.isEmpty ? [:] : PLPhotos.candidates(players, entries: entries, keep: keep)
    }

    func espnNames(clubID: Int) async -> [String]? {
        guard let info = try? await clubs().first(where: { $0.club.id == clubID }) else { return nil }
        return [info.club.name, info.club.shortName].compactMap { $0 }
    }
}
