import Foundation

/// API 키가 없을 때와 SwiftUI 프리뷰에서 쓰는 샘플 데이터. 실제 기록이 아닙니다.
public enum Sample {
    public static func logo(_ id: Int) -> URL? {
        URL(string: "https://media.api-sports.io/football/teams/\(id).png")
    }

    public static let everton = Club(id: 45, name: "Everton", logoURL: logo(45))
    private static let opponents: [Club] = [
        Club(id: 52, name: "Crystal Palace", logoURL: logo(52)),
        Club(id: 40, name: "Liverpool", logoURL: logo(40)),
        Club(id: 66, name: "Aston Villa", logoURL: logo(66)),
        Club(id: 47, name: "Tottenham", logoURL: logo(47)),
        Club(id: 50, name: "Manchester City", logoURL: logo(50)),
        Club(id: 34, name: "Newcastle", logoURL: logo(34)),
        Club(id: 33, name: "Manchester United", logoURL: logo(33)),
        Club(id: 42, name: "Arsenal", logoURL: logo(42)),
    ]

    public static var matches: [Match] {
        let now = Date()
        let day: TimeInterval = 86_400
        let scores: [(Int, Int)] = [(2, 1), (0, 0), (1, 2), (3, 1), (1, 0)]
        var list: [Match] = []
        for (i, score) in scores.enumerated() {
            let home = i % 2 == 0
            let club = opponents[i]
            list.append(Match(
                id: 100 + i, kickoff: now.addingTimeInterval(-day * Double(7 * (scores.count - i))),
                competition: "Premier League", round: "Regular Season - \(i + 1)", venue: "Hill Dickinson Stadium",
                home: home ? everton : club, away: home ? club : everton,
                homeGoals: home ? score.0 : score.1, awayGoals: home ? score.1 : score.0,
                phase: .finished, statusText: "Match Finished", elapsed: 90))
        }
        for i in 0..<4 {
            let home = i % 2 == 1
            let club = opponents[(i + 5) % opponents.count]
            list.append(Match(
                id: 200 + i, kickoff: now.addingTimeInterval(day * Double(3 + 7 * i)),
                competition: "Premier League", round: "Regular Season - \(i + 6)", venue: "Hill Dickinson Stadium",
                home: home ? everton : club, away: home ? club : everton,
                homeGoals: nil, awayGoals: nil, phase: .upcoming, statusText: "Not Started", elapsed: nil))
        }
        return list
    }

    public static let players: [Player] = {
        func p(_ id: Int, _ name: String, _ n: Int, _ pos: Position, _ age: Int, _ rating: Double,
               g: Int = 0, a: Int = 0) -> Player {
            Player(id: id, name: name, number: n, position: pos, age: age, nationality: "England", photoURL: nil,
                   stats: PlayerStats(appearances: 10, minutes: 860, rating: rating, goals: g, assists: a,
                                      shots: 14 + g * 3, shotsOnTarget: 6 + g, passes: 410, keyPasses: 9 + a,
                                      passAccuracy: 78, tackles: 21, dribbles: 12, yellow: 1, red: 0,
                                      saves: pos == .goalkeeper ? 31 : 0, conceded: pos == .goalkeeper ? 9 : 0))
        }
        return [
            p(1, "J. Pickford", 1, .goalkeeper, 32, 7.1),
            p(2, "J. Tarkowski", 6, .defender, 33, 6.9),
            p(3, "J. Branthwaite", 32, .defender, 24, 7.0),
            p(4, "V. Mykolenko", 16, .defender, 27, 6.8),
            p(5, "J. Garner", 37, .midfielder, 25, 7.2, a: 2),
            p(6, "K. Dewsbury-Hall", 22, .midfielder, 27, 7.0, g: 1, a: 3),
            p(7, "I. Ndiaye", 10, .attacker, 26, 7.4, g: 4, a: 1),
            p(8, "T. Barry", 11, .attacker, 33, 6.7, g: 3),
        ]
    }()

    public static var detail: MatchDetail {
        let match = matches[0]
        let stats = [
            StatLine(label: "점유율", home: 54, away: 46, isPercent: true),
            StatLine(label: "슈팅", home: 13, away: 9, isPercent: false),
            StatLine(label: "유효슈팅", home: 6, away: 3, isPercent: false),
            StatLine(label: "코너킥", home: 5, away: 4, isPercent: false),
            StatLine(label: "파울", home: 10, away: 12, isPercent: false),
        ]
        let formation = ["1:1", "2:1", "2:2", "2:3", "2:4", "3:1", "3:2", "3:3", "4:1", "4:2", "4:3"]
        let starters = players.enumerated().map { index, pl in
            LineupPlayer(id: pl.id, name: pl.name, number: pl.number, position: pl.position.short,
                         grid: formation[index], rating: pl.stats?.rating, photoURL: nil)
        }
        let lineup = TeamLineup(club: everton, formation: "4-3-3", starters: starters, substitutes: [])
        return MatchDetail(match: match, stats: stats, lineups: [lineup])
    }

    public static func events(for match: Match) -> [MatchEvent] {
        guard let h = match.homeGoals, let a = match.awayGoals else { return [] }
        var list: [MatchEvent] = []
        var id = 1
        for i in 0..<h { list.append(MatchEvent(id: id, minute: 12 + i * 31, extra: nil, clubID: match.home.id, player: "샘플 선수", assist: nil, kind: .goal)); id += 1 }
        for i in 0..<a { list.append(MatchEvent(id: id, minute: 27 + i * 33, extra: nil, clubID: match.away.id, player: "샘플 선수", assist: nil, kind: .goal)); id += 1 }
        list.append(MatchEvent(id: id, minute: 58, extra: nil, clubID: match.home.id, player: "샘플 선수", assist: nil, kind: .yellow))
        return list.sorted { $0.minute < $1.minute }
    }

    public static let standings: [StandingRow] = {
        let names: [(Int, String)] = [(42, "Arsenal"), (50, "Manchester City"), (40, "Liverpool"), (33, "Manchester United"),
                                      (34, "Newcastle"), (47, "Tottenham"), (45, "Everton"), (66, "Aston Villa"), (52, "Crystal Palace")]
        return names.enumerated().map { index, entry in
            StandingRow(rank: index + 1, club: Club(id: entry.0, name: entry.1, logoURL: logo(entry.0)),
                        played: 12, won: 9 - index, drawn: 2, lost: index, goalsFor: 24 - index, goalsAgainst: 10 + index,
                        points: 29 - index * 2, form: "WDWLW",
                        note: index < 4 ? "Promotion - Champions League (League phase)" : (index > 7 ? "Relegation - Championship" : nil))
        }
    }()

    public static let news: [NewsItem] = [
        NewsItem(id: "s1", title: "Everton make strong start to the new season",
                 summary: "The Blues have picked up momentum after a solid run of results at home.",
                 link: nil, date: Date(), imageURL: nil),
        NewsItem(id: "s2", title: "Team news ahead of the weekend fixture",
                 summary: "The manager gives an update on injuries and the likely starting eleven.",
                 link: nil, date: Date().addingTimeInterval(-86_400), imageURL: nil),
    ]
}

public struct MockFootballService: FootballService {
    public init() {}
    public func matches() async throws -> [Match] { Sample.matches }
    public func detail(of match: Match) async throws -> MatchDetail {
        let base = Sample.detail
        return MatchDetail(match: match, stats: base.stats, lineups: base.lineups, events: Sample.events(for: match))
    }
    public func squad() async throws -> [Player] { Sample.players }
    public func standings() async throws -> [StandingRow] { Sample.standings }
    public func diagnostics() async -> DataReport {
        DataReport(seasonFound: true, seasonStart: "2026-08-15", seasonEnd: "2027-05-30",
                   fixtureCount: Sample.matches.count, squadCount: Sample.players.count,
                   missingNumbers: 0, missingPhotos: Sample.players.count,
                   nextMatchDate: Sample.matches.nextMatch()?.kickoff,
                   errors: ["샘플 데이터입니다. API 키를 설정하면 실제 점검 결과가 표시됩니다."])
    }
}

public struct MockNewsService: NewsService {
    public init() {}
    public func headlines() async throws -> [NewsItem] { Sample.news }
}
