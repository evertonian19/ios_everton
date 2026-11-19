import Foundation

/// 프리미어리그 공개 선수단 HTML 파싱과 이름 매칭 (순수 함수, 네트워크 없음).
enum PLSquadParser {
    struct Entry: Equatable { let id: String; let slug: String }

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

    /// 선수단 HTML 의 <title> 에서 PL 구단명을 읽는다 ("Everton Squad Information & ..." → "Everton").
    static func clubName(_ html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"<title>\s*(.*?)\s+Squad Information"#, options: [.dotMatchesLineSeparators]),
              let m = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(m.range(at: 1), in: html) else { return nil }
        return html[r].split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
