import Foundation
import EvCore

/// ESPN 로스터의 신상(생년월일·키·국적)이 동명이인과 섞여 틀리는 경우가 있어(예: Thierno Barry 가 기니 선수 정보로 나옴)
/// Wikidata 로 교차 검증·보정한다. 규칙은 대시보드 backend/wikidata.py 와 같다.
///  - 같은 구단에 현재 소속(P54, 종료일 없음)인 항목 중 이름이 같은 후보가 정확히 1명일 때만 보정
///  - 값이 비정상(키 150~215cm, 나이 15~45 밖)이면 버림
///  - 수동 보정(PlayerBio.overrides)이 최종 권위
public struct BioFacts: Sendable, Equatable {
    var birthDate: Date?
    var heightCM: Int?
    var nationality: String?
    var birthPlace: String?
    var iso3: String?
}

public enum PlayerBio {
    /// 수동 보정. 키는 ESPN athlete id. 대시보드 backend/ios_player_overrides.json 과 같은 내용을 유지한다.
    static let overrides: [Int: BioFacts] = [
        301166: BioFacts(birthDate: PlayerBio.day("2002-10-21"), heightCM: 195, nationality: "France", birthPlace: nil, iso3: "fra"),
    ]

    static func day(_ text: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: text)
    }

    static func dayText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func age(_ born: Date, now: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.dateComponents([.year], from: born, to: now).year ?? 0
    }

    static func sane(_ facts: BioFacts, now: Date = Date()) -> Bool {
        if let h = facts.heightCM, !(150...215).contains(h) { return false }
        if let b = facts.birthDate, !(15...45).contains(age(b, now: now)) { return false }
        return true
    }

    /// 사진 라이선스가 자유(CC BY·CC BY-SA·CC0·퍼블릭 도메인)인지. NC/ND·Fair use 는 거부.
    static func isFreeLicense(_ text: String) -> Bool {
        let t = text.lowercased().trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        let bad = ["fair use", "non-free", "all rights reserved", "-nc", "-nd", " nc", " nd"]
        if bad.contains(where: { t.contains($0) }) { return false }
        return ["cc by", "cc-by", "cc0", "cc zero", "public domain", "pd", "attribution", "gfdl"].contains { t.hasPrefix($0) }
    }

    /// HTML 태그·엔티티를 제거한 짧은 문구 (작성자 표기용).
    static func plain(_ html: String?) -> String {
        var text = (html ?? "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        for (entity, char) in [("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'")] {
            text = text.replacingOccurrences(of: entity, with: char)
        }
        return String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
    }

    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
        let cleaned = folded.replacingOccurrences(of: "'", with: "")
            .map { $0.isLetter || $0.isNumber ? String($0) : " " }.joined()
        return cleaned.split(separator: " ").joined(separator: " ")
    }

    private static let homeNations: Set<String> = ["england", "scotland", "wales", "northern ireland"]

    /// ESPN 값 위에 found 를 덮어쓰고, 달랐던 항목은 bioDisputed 에 ESPN 원본으로 남긴다.
    static func apply(_ player: Player, _ found: BioFacts, source: String, now: Date = Date()) -> Player {
        var out = player
        var disputed = player.bioDisputed
        let keep = normalize(found.nationality ?? "") == "united kingdom"
            && homeNations.contains(normalize(player.nationality ?? ""))      // England 등은 UK 보다 구체적이므로 유지
        if let n = found.nationality, !keep {
            if let old = player.nationality, normalize(old) != normalize(n) { disputed["nationality"] = old }
            out.nationality = n
        }
        if let b = found.birthDate {
            if let old = player.birthDate, old != b { disputed["birthDate"] = PlayerBio.dayText(old) }
            out.birthDate = b
            out.age = age(b, now: now)
        }
        if let h = found.heightCM {
            if let old = player.heightCM, abs(old - h) > 3 { disputed["heightCM"] = "\(old) cm" }
            out.heightCM = h
        }
        if let place = found.birthPlace { out.birthPlace = place }
        if disputed["nationality"] != nil || disputed["birthDate"] != nil {
            out.weightKG = nil                                     // 다른 사람 프로필이 섞였다면 몸무게도 신뢰할 수 없다
            out.flagURL = found.iso3.flatMap { URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/\($0.lowercased()).png") }
                ?? player.flagURL
        }
        out.bioSource = source
        out.bioDisputed = disputed
        out.bioVerified = true
        return out
    }

    /// 수동 보정만 적용(네트워크 없음). Wikidata 보정 뒤에 한 번 더 호출해 최종 권위로 덮어쓴다.
    public static func applyOverrides(_ players: [Player]) -> [Player] {
        players.map { player in
            guard let ov = overrides[player.id] else { return player }
            var out = apply(player, ov, source: "override")
            if let iso = ov.iso3 { out.flagURL = URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/\(iso).png") }
            return out
        }
    }
}

/// Wikidata API. 빠른 연속 호출에 429 를 주므로 직렬 호출 + 간격 + 쿨다운, 결과는 DiskCache(7일)에 보관한다.
public actor WikidataBio {
    private let session: URLSession
    private let cache: DiskCache
    private var lastCall = Date.distantPast
    private var blockedUntil = Date.distantPast
    private let ttl: TimeInterval = 7 * 86_400
    private let api = "https://www.wikidata.org/w/api.php"
    private let commonsAPI = "https://commons.wikimedia.org/w/api.php"
    private let everton = "Q5794"                      // Everton F.C. (다른 구단 QID 는 이름 검색으로 찾는다)

    public init(session: URLSession = .shared, cache: DiskCache = DiskCache()) {
        self.session = session
        self.cache = cache
    }

    private func call(_ items: [String: String], base: String? = nil) async throws -> Data {
        var comps = URLComponents(string: base ?? api)!
        comps.queryItems = (items.merging(["format": "json", "formatversion": "2"]) { $1 })
            .sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        let url = comps.url!
        let key = "wd_" + url.absoluteString
        if let data = await cache.data(for: key, maxAge: ttl) { return data }
        if Date() < blockedUntil { throw ServiceError.server("Wikidata 쿨다운 중") }
        let wait = lastCall.addingTimeInterval(1.0).timeIntervalSinceNow
        if wait > 0 { try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
        defer { lastCall = Date() }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 {
                let retry = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 90
                blockedUntil = Date().addingTimeInterval(min(max(retry, 30), 600))
                throw ServiceError.badResponse(429)
            }
            guard (200..<300).contains(http.statusCode) else { throw ServiceError.badResponse(http.statusCode) }
        }
        await cache.store(data, for: key)
        return data
    }

    private struct Search: Decodable {
        struct Hit: Decodable { let id: String; let description: String? }
        let search: [Hit]?
    }

    private struct Entities: Decodable {
        /// Wikidata 의 값은 항목에 따라 객체(id/time/amount…)이거나 문자열(ISO 코드 등)이다.
        struct Value: Decodable {
            let id: String?, time: String?, amount: String?, unit: String?, precision: Int?, text: String?
            private enum Keys: String, CodingKey { case id, time, amount, unit, precision }
            init(from decoder: Decoder) throws {
                if let single = try? decoder.singleValueContainer(), let string = try? single.decode(String.self) {
                    (id, time, amount, unit, precision, text) = (nil, nil, nil, nil, nil, string)
                    return
                }
                let c = try decoder.container(keyedBy: Keys.self)
                id = try? c.decode(String.self, forKey: .id)
                time = try? c.decode(String.self, forKey: .time)
                amount = try? c.decode(String.self, forKey: .amount)
                unit = try? c.decode(String.self, forKey: .unit)
                precision = try? c.decode(Int.self, forKey: .precision)
                text = nil
            }
        }
        struct Snak: Decodable { struct DV: Decodable { let value: Value? }; let datavalue: DV? }
        struct Claim: Decodable { let mainsnak: Snak?; let qualifiers: [String: [Snak]]?; let rank: String? }
        struct Label: Decodable { let value: String }
        struct Entity: Decodable {
            let labels: [String: Label]?
            let aliases: [String: [Label]]?
            let claims: [String: [Claim]]?
        }
        let entities: [String: Entity]?
    }

    private func entities(_ ids: [String]) async throws -> [String: Entities.Entity] {
        guard !ids.isEmpty else { return [:] }
        let data = try await call(["action": "wbgetentities", "ids": ids.joined(separator: "|"),
                                   "props": "claims|labels|aliases", "languages": "en"])
        return try JSONDecoder().decode(Entities.self, from: data).entities ?? [:]
    }

    private func firstValue(_ e: Entities.Entity, _ prop: String) -> Entities.Value? {
        e.claims?[prop]?.compactMap { $0.mainsnak?.datavalue?.value }.first
    }

    private func ids(_ e: Entities.Entity, _ prop: String) -> [String] {
        e.claims?[prop]?.compactMap { $0.mainsnak?.datavalue?.value?.id } ?? []
    }

    private func image(_ e: Entities.Entity) -> String? {
        let claims = e.claims?["P18"] ?? []
        return (claims.first { $0.rank == "preferred" } ?? claims.first)?.mainsnak?.datavalue?.value?.text
    }

    private func birthDay(_ e: Entities.Entity) -> String? {
        guard let v = firstValue(e, "P569"), (v.precision ?? 0) >= 11, let t = v.time else { return nil }
        return String(t.drop(while: { $0 == "+" }).prefix(10))
    }

    private func isCurrentMember(_ e: Entities.Entity, of team: String) -> Bool {
        (e.claims?["P54"] ?? []).contains { claim in
            claim.mainsnak?.datavalue?.value?.id == team && (claim.qualifiers?["P582"] ?? []).isEmpty
        }
    }

    private func nameMatches(_ name: String, _ e: Entities.Entity) -> Bool {
        let want = PlayerBio.normalize(name)
        var names = (e.aliases?["en"] ?? []).map(\.value)
        if let label = e.labels?["en"]?.value { names.append(label) }
        return names.contains { PlayerBio.normalize($0) == want }
    }

    private func facts(_ e: Entities.Entity, labels: [String: Entities.Entity]) -> BioFacts? {
        var out = BioFacts()
        if let v = firstValue(e, "P569"), (v.precision ?? 0) >= 11, let t = v.time {
            out.birthDate = PlayerBio.day(String(t.drop(while: { $0 == "+" }).prefix(10)))
        }
        if let v = firstValue(e, "P2048"), let amount = v.amount.flatMap({ Double($0) }) {
            let scale: Double = v.unit?.hasSuffix("Q11573") == true ? 100 : v.unit?.hasSuffix("Q174728") == true ? 1 : 0
            if scale > 0 { out.heightCM = Int((amount * scale).rounded()) }
        }
        let countries = ids(e, "P27")
        let names = countries.compactMap { labels[$0]?.labels?["en"]?.value }
        if !countries.isEmpty && names.isEmpty { return nil }      // 국적 이름을 아직 못 받음 → 반쪽 보정 금지
        out.nationality = names.first
        out.iso3 = countries.compactMap { id in labels[id].flatMap { firstValue($0, "P298")?.text } }.first
        if let place = ids(e, "P19").first { out.birthPlace = labels[place]?.labels?["en"]?.value }
        return PlayerBio.sane(out) ? out : nil
    }

    // MARK: 사진 (Wikimedia Commons, 자유 라이선스만)

    private struct ImageInfo: Decodable {
        struct Meta: Decodable { let value: String? }
        struct Info: Decodable {
            let thumburl: String?
            let descriptionurl: String?
            let extmetadata: [String: Meta]?
        }
        struct Page: Decodable { let title: String?; let imageinfo: [Info]? }
        struct Query: Decodable { let pages: [Page]? }
        let query: Query?
    }

    /// 파일명 → (썸네일, 표기). 자유 라이선스가 아니거나 응답이 없으면 빠진다.
    private func commons(_ files: [String]) async -> [String: (url: URL, credit: PhotoCredit)] {
        var out: [String: (url: URL, credit: PhotoCredit)] = [:]
        let names = Array(Set(files.map { $0.replacingOccurrences(of: "_", with: " ") })).sorted()
        for start in stride(from: 0, to: names.count, by: 40) {
            let chunk = Array(names[start..<min(start + 40, names.count)])
            guard let data = try? await call(["action": "query", "prop": "imageinfo", "iiprop": "url|extmetadata", "iiurlwidth": "320",
                                              "titles": chunk.map { "File:" + $0 }.joined(separator: "|")], base: commonsAPI),
                  let decoded = try? JSONDecoder().decode(ImageInfo.self, from: data) else { continue }
            for page in decoded.query?.pages ?? [] {
                guard let info = page.imageinfo?.first, let thumb = info.thumburl.flatMap(URL.init(string:)),
                      let name = page.title?.split(separator: ":", maxSplits: 1).last.map(String.init) else { continue }
                let meta = info.extmetadata ?? [:]
                let license = PlayerBio.plain(meta["LicenseShortName"]?.value)
                guard PlayerBio.isFreeLicense(license) else { continue }
                let author = PlayerBio.plain(meta["Artist"]?.value)
                out[name] = (thumb, PhotoCredit(author: author.isEmpty ? "Wikimedia Commons" : author, license: license,
                                                licenseURL: meta["LicenseUrl"]?.value.flatMap(URL.init(string:)),
                                                pageURL: info.descriptionurl.flatMap(URL.init(string:))))
            }
        }
        return out
    }

    /// 선수 목록을 보정해서 돌려준다. 네트워크/쿨다운 문제는 조용히 넘기고 ESPN 값을 그대로 둔다.
    public func enrich(_ players: [Player], teamQID: String? = nil) async -> [Player] {
        let team = teamQID ?? everton
        var result = players
        do {
            var candidates: [Int: [String]] = [:]
            for p in players {
                let data = try await call(["action": "wbsearchentities", "search": p.name, "language": "en", "type": "item", "limit": "10"])
                let hits = try JSONDecoder().decode(Search.self, from: data).search ?? []
                candidates[p.id] = hits.filter { ($0.description ?? "").lowercased().contains("foot") || $0.description == nil }.map(\.id)
            }
            let ents = try await entities(Array(Set(candidates.values.flatMap { $0 })))
            var matched: [Int: Entities.Entity] = [:]
            var wanted = Set<String>()
            for p in players {
                let hits = (candidates[p.id] ?? []).compactMap { ents[$0] }.filter { isCurrentMember($0, of: team) && nameMatches(p.name, $0) }
                if hits.count == 1 { matched[p.id] = hits[0]; wanted.formUnion(ids(hits[0], "P27") + ids(hits[0], "P19")) }
            }
            let labels = try await entities(Array(wanted))
            // 사진은 정체가 확실한 항목에서만: 소속 일치로 매칭됐거나, 이름·생년월일이 ESPN 과 같은 단 하나의 후보.
            var photoFile: [Int: String] = [:]
            for p in players {
                if let e = matched[p.id], let file = image(e) { photoFile[p.id] = file; continue }
                guard matched[p.id] == nil, let born = p.birthDate.map(PlayerBio.dayText) else { continue }
                let same = (candidates[p.id] ?? []).compactMap { ents[$0] }.filter { nameMatches(p.name, $0) && birthDay($0) == born }
                if same.count == 1, let file = image(same[0]) { photoFile[p.id] = file }
            }
            let pictures = await commons(Array(Set(photoFile.values)))
            result = players.map { p in
                var q = p
                if let e = matched[p.id], let found = facts(e, labels: labels) { q = PlayerBio.apply(p, found, source: "wikidata") }
                if let file = photoFile[p.id], let pic = pictures[file.replacingOccurrences(of: "_", with: " ")] {
                    q.photoURL = pic.url
                    q.photoCredit = pic.credit
                }
                return q
            }
        } catch {
            // 429·네트워크 오류: 이미 캐시된 응답으로 얻은 만큼만 반영된 상태. 다음 새로고침에서 이어서 채운다.
        }
        return PlayerBio.applyOverrides(result)
    }
}
