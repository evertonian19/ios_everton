import Foundation
import EvCore

/// ESPN 응답 → 앱 모델. 규칙은 대시보드의 backend/espn.py 와 같다.
enum ESPNMapping {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let isoShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        return f
    }()
    private static let dayOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// ESPN 은 "2026-11-06T20:00Z" 처럼 초가 없는 시각을 준다.
    static func date(_ text: String) -> Date? {
        isoShort.date(from: text) ?? isoFormatter.date(from: text)
    }

    static func club(_ team: ESPNTeam) -> Club {
        let logo = (team.logos?.first?.href ?? team.logo).flatMap(URL.init(string:))
        return Club(id: team.id.int ?? 0, name: team.displayName ?? "?", logoURL: logo,
                    shortName: team.shortDisplayName, code: team.abbreviation)
    }

    // MARK: 일정

    static func match(_ event: ESPNEvent) -> Match? {
        guard let id = event.id.int, let kickoff = date(event.date),
              let comp = event.competitions?.first,
              let home = comp.competitors?.first(where: { $0.homeAway == "home" }),
              let away = comp.competitors?.first(where: { $0.homeAway == "away" }) else { return nil }
        let state = comp.status?.type?.state ?? "pre"
        let phase: MatchPhase = state == "post" ? .finished : state == "in" ? .live : state == "pre" ? .upcoming : .other
        return Match(id: id, kickoff: kickoff, competition: "Premier League", round: "", venue: comp.venue?.fullName,
                     home: club(home.team), away: club(away.team),
                     homeGoals: phase == .upcoming ? nil : home.score?.value,
                     awayGoals: phase == .upcoming ? nil : away.score?.value,
                     phase: phase, statusText: comp.status?.type?.description ?? "", elapsed: nil)
    }

    /// 지난 경기와 예정 경기 응답을 합쳐 시간순으로 정렬한다.
    static func schedule(_ lists: [ESPNSchedule]) -> [Match] {
        var byID: [Int: Match] = [:]
        for list in lists { for event in list.events ?? [] { if let m = match(event) { byID[m.id] = m } } }
        return byID.values.sorted { $0.kickoff < $1.kickoff }
    }

    // MARK: 선수

    static func position(_ abbreviation: String?) -> Position {
        switch abbreviation?.uppercased().first {
        case "G": return .goalkeeper
        case "D": return .defender
        case "M": return .midfielder
        default: return .attacker
        }
    }

    private static let statNames: [(String, WritableKeyPath<PlayerStats, Int>)] = [
        ("appearances", \.appearances), ("subIns", \.subIns), ("totalGoals", \.goals), ("goalAssists", \.assists),
        ("totalShots", \.shots), ("shotsOnTarget", \.shotsOnTarget), ("foulsCommitted", \.foulsCommitted),
        ("foulsSuffered", \.foulsSuffered), ("offsides", \.offsides), ("yellowCards", \.yellow), ("redCards", \.red),
        ("ownGoals", \.ownGoals), ("saves", \.saves), ("goalsConceded", \.conceded), ("shotsFaced", \.shotsFaced),
    ]

    static func stats(_ athlete: ESPNAthlete) -> PlayerStats? {
        let categories = athlete.statistics?.splits?.categories ?? []
        var values: [String: Double] = [:]
        for category in categories { for stat in category.stats ?? [] { if let n = stat.name, let v = stat.value { values[n] = v } } }
        guard !values.isEmpty else { return nil }
        var result = PlayerStats()
        for (name, path) in statNames { result[keyPath: path] = Int(values[name] ?? 0) }
        return result
    }

    static func player(_ a: ESPNAthlete) -> Player? {
        guard let id = a.id.int else { return nil }
        let place = [a.birthPlace?.city, a.birthPlace?.state, a.birthPlace?.country].compactMap { $0 }.joined(separator: ", ")
        return Player(
            id: id, name: a.displayName ?? a.fullName ?? "?", number: a.jersey.flatMap(Int.init),
            position: position(a.position?.abbreviation), age: a.age, nationality: a.citizenship, photoURL: nil,
            stats: stats(a), heightCM: a.height.map { Int(($0 * 2.54).rounded()) },
            weightKG: a.weight.map { Int(($0 * 0.45359).rounded()) },
            birthDate: a.dateOfBirth.flatMap { dayOnly.date(from: String($0.prefix(10))) },
            birthPlace: place.isEmpty ? nil : place, flagURL: a.flag?.href.flatMap(URL.init(string:)))
    }

    static func roster(_ payload: ESPNRoster) -> [Player] {
        let order: [Position: Int] = [.goalkeeper: 0, .defender: 1, .midfielder: 2, .attacker: 3]
        return (payload.athletes ?? []).compactMap(player).sorted {
            let (a, b) = (order[$0.position] ?? 9, order[$1.position] ?? 9)
            return a != b ? a < b : ($0.number ?? 999) < ($1.number ?? 999)
        }
    }

    // MARK: 구단 · 순위

    static func clubs(_ payload: ESPNTeams) -> [ClubInfo] {
        let teams = payload.sports?.first?.leagues?.first?.teams ?? []
        return teams.map { entry in
            let c = club(entry.team)
            return ClubInfo(club: c, code: c.code, country: "England")
        }
        .sorted { $0.club.name < $1.club.name }
    }

    static func standings(_ payload: ESPNStandings) -> [StandingRow] {
        let entries = payload.children?.first?.standings?.entries ?? []
        return entries.map { entry in
            var s: [String: Double] = [:]
            for stat in entry.stats ?? [] { if let n = stat.name, let v = stat.value { s[n] = v } }
            return StandingRow(rank: Int(s["rank"] ?? 0), club: club(entry.team), played: Int(s["gamesPlayed"] ?? 0),
                               won: Int(s["wins"] ?? 0), drawn: Int(s["ties"] ?? 0), lost: Int(s["losses"] ?? 0),
                               goalsFor: Int(s["pointsFor"] ?? 0), goalsAgainst: Int(s["pointsAgainst"] ?? 0),
                               points: Int(s["points"] ?? 0), form: "", note: entry.note?.description)
        }
        .sorted { ($0.rank == 0 ? 99 : $0.rank) < ($1.rank == 0 ? 99 : $1.rank) }
    }

    // MARK: 경기 요약

    private static let statSpecs: [(key: String, label: String, percent: Bool)] = [
        ("possessionPct", "점유율", true), ("totalShots", "슈팅", false), ("shotsOnTarget", "유효슈팅", false),
        ("wonCorners", "코너킥", false), ("foulsCommitted", "파울", false), ("offsides", "오프사이드", false),
        ("passPct", "패스 성공률", true), ("totalTackles", "태클", false), ("yellowCards", "경고", false), ("saves", "선방", false),
    ]

    static func statLines(_ payload: ESPNSummary, homeID: Int, awayID: Int) -> [StatLine] {
        func values(_ id: Int) -> [String: Double] {
            var out: [String: Double] = [:]
            let team = payload.boxscore?.teams?.first { $0.team.id.int == id }
            for stat in team?.statistics ?? [] { if let n = stat.name, let t = stat.displayValue, let v = Double(t) { out[n] = v } }
            return out
        }
        let (h, a) = (values(homeID), values(awayID))
        return statSpecs.compactMap { line in
            guard var hv = h[line.key], var av = a[line.key] else { return nil }
            if line.key == "passPct", hv <= 1, av <= 1 { hv *= 100; av *= 100 }   // 0.8 → 80%
            return StatLine(label: line.label, home: hv, away: av, isPercent: line.percent)
        }
    }

    /// 포지션 약어 → 세로 깊이. 포메이션 숫자(4-2-3-1)로 줄을 나누고 줄 안은 가로 위치로 정렬한다.
    private static func depth(_ abbr: String?) -> Double {
        let a = (abbr ?? "").uppercased()
        if a.hasPrefix("G") { return 0 }
        if ["CD", "CD-L", "CD-R", "CB", "SW", "LB", "RB", "LWB", "RWB", "WB", "D"].contains(a) { return 1 }
        if ["DM", "CDM", "DM-L", "DM-R"].contains(a) { return 1.8 }
        if ["CM", "CM-L", "CM-R", "LM", "RM", "M"].contains(a) { return 2.4 }
        if a.hasPrefix("AM") || ["LW", "RW", "W"].contains(a) { return 3 }
        return 4
    }

    private static func side(_ abbr: String?) -> Int {
        let a = (abbr ?? "").uppercased()
        if ["LB", "LWB", "LM", "LW"].contains(a) { return 0 }
        if a.hasSuffix("-L") { return 1 }
        if a.hasSuffix("-R") { return 3 }
        if ["RB", "RWB", "RM", "RW"].contains(a) { return 4 }
        return 2
    }

    /// 선발 11명을 "행:열"(1행 = 골키퍼)로 배치한다. 포메이션 문자열이 안 맞으면 깊이로 줄을 묶는다.
    static func layout(formation: String?, starters: [(place: Int, position: String?)]) -> [Int: String] {
        var rows = [1] + (formation ?? "").split(separator: "-").compactMap { Int($0) }
        let ordered = starters.sorted {
            let (d0, d1) = (depth($0.position), depth($1.position))
            if d0 != d1 { return d0 < d1 }
            let (s0, s1) = (side($0.position), side($1.position))
            return s0 != s1 ? s0 < s1 : $0.place < $1.place
        }
        if rows.reduce(0, +) != ordered.count {
            rows = []
            var last: Double?
            for item in ordered {
                let d = depth(item.position)
                if d != last { rows.append(0); last = d }
                rows[rows.count - 1] += 1
            }
        }
        var grid: [Int: String] = [:]
        var index = 0
        for (r, count) in rows.enumerated() {
            for c in 1...max(count, 1) where index < ordered.count && count > 0 {
                grid[ordered[index].place] = "\(r + 1):\(c)"
                index += 1
            }
        }
        return grid
    }

    static func lineups(_ payload: ESPNSummary) -> [TeamLineup] {
        (payload.rosters ?? []).compactMap { side in
            guard let team = side.team else { return nil }
            let entries = side.roster ?? []
            let starters = entries.filter { $0.starter == true }
            let grid = starters.count == 11
                ? layout(formation: side.formation,
                         starters: starters.map { (place: Int($0.formationPlace ?? "") ?? 0, position: $0.position?.abbreviation) })
                : [:]
            func convert(_ e: ESPNSummary.RosterEntry, placed: Bool) -> LineupPlayer {
                LineupPlayer(id: e.athlete?.id?.int ?? 0, name: e.athlete?.displayName ?? "?", number: e.jersey.flatMap(Int.init),
                             position: e.position?.abbreviation,
                             grid: placed ? grid[Int(e.formationPlace ?? "") ?? -1] : nil)
            }
            return TeamLineup(club: club(team), formation: side.formation,
                              starters: starters.map { convert($0, placed: true) },
                              substitutes: entries.filter { $0.starter != true }.map { convert($0, placed: false) })
        }
    }

    private static func minute(_ text: String?) -> (Int, Int?) {
        let clean = (text ?? "").replacingOccurrences(of: "'", with: "")
        let parts = clean.split(separator: "+", omittingEmptySubsequences: false)
        return (Int(parts.first ?? "") ?? 0, parts.count > 1 ? Int(parts[1]) : nil)
    }

    static func events(_ payload: ESPNSummary) -> [MatchEvent] {
        var list: [MatchEvent] = []
        for (index, e) in (payload.keyEvents ?? []).enumerated() {
            let type = (e.type?.type ?? "").lowercased(), label = (e.type?.text ?? "").lowercased()
            let kind: MatchEventKind
            if label.contains("own") && label.contains("goal") { kind = .ownGoal }
            else if type.hasPrefix("goal") || label.contains("penalty - scored") { kind = .goal }
            else if label.contains("yellow") { kind = .yellow }
            else if label.contains("red") { kind = .red }
            else if label.contains("missed") && label.contains("penalty") { kind = .missedPenalty }
            else { continue }
            let (min, extra) = minute(e.clock?.displayValue)
            let people = (e.participants ?? []).compactMap { $0.athlete?.displayName }
            list.append(MatchEvent(id: e.id?.int ?? index, minute: min, extra: extra, clubID: e.team?.id.int ?? 0,
                                   player: people.first ?? "-", assist: kind == .goal && people.count > 1 ? people[1] : nil,
                                   kind: kind))
        }
        return list.sorted { ($0.minute, $0.extra ?? 0) < ($1.minute, $1.extra ?? 0) }
    }
}
