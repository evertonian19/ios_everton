import Foundation

/// 오프라인·프리뷰용 스냅샷. 2026-11-19 에 ESPN 에서 받은 실제 데이터이며(스쿼드·순위·일정 일부), 네트워크가 되면 항상 실시간 값으로 대체된다.
public enum Sample {
    public static let snapshotDate = "2026-11-19"

    public static func logo(_ id: Int) -> URL? { URL(string: "https://a.espncdn.com/i/teamlogos/soccer/500/\(id).png") }

    public static let everton = Club(id: 368, name: "Everton", logoURL: logo(368), shortName: "Everton", code: "EVE")

    public static let league: [Club] = [
        Club(id: 349, name: "AFC Bournemouth", logoURL: logo(349), shortName: "Bournemouth", code: "BOU"),
        Club(id: 359, name: "Arsenal", logoURL: logo(359), shortName: "Arsenal", code: "ARS"),
        Club(id: 362, name: "Aston Villa", logoURL: logo(362), shortName: "Aston Villa", code: "AVL"),
        Club(id: 337, name: "Brentford", logoURL: logo(337), shortName: "Brentford", code: "BRE"),
        Club(id: 331, name: "Brighton & Hove Albion", logoURL: logo(331), shortName: "Brighton", code: "BHA"),
        Club(id: 363, name: "Chelsea", logoURL: logo(363), shortName: "Chelsea", code: "CHE"),
        Club(id: 388, name: "Coventry City", logoURL: logo(388), shortName: "Coventry", code: "COV"),
        Club(id: 384, name: "Crystal Palace", logoURL: logo(384), shortName: "C Palace", code: "CRY"),
        Club(id: 368, name: "Everton", logoURL: logo(368), shortName: "Everton", code: "EVE"),
        Club(id: 370, name: "Fulham", logoURL: logo(370), shortName: "Fulham", code: "FUL"),
        Club(id: 306, name: "Hull City", logoURL: logo(306), shortName: "Hull", code: "HUL"),
        Club(id: 373, name: "Ipswich Town", logoURL: logo(373), shortName: "Ipswich", code: "IPS"),
        Club(id: 357, name: "Leeds United", logoURL: logo(357), shortName: "Leeds", code: "LEE"),
        Club(id: 364, name: "Liverpool", logoURL: logo(364), shortName: "Liverpool", code: "LIV"),
        Club(id: 382, name: "Manchester City", logoURL: logo(382), shortName: "Man City", code: "MNC"),
        Club(id: 360, name: "Manchester United", logoURL: logo(360), shortName: "Man Utd", code: "MAN"),
        Club(id: 361, name: "Newcastle United", logoURL: logo(361), shortName: "Newcastle", code: "NEW"),
        Club(id: 393, name: "Nottingham Forest", logoURL: logo(393), shortName: "Nottm Forest", code: "NFO"),
        Club(id: 366, name: "Sunderland", logoURL: logo(366), shortName: "Sunderland", code: "SUN"),
        Club(id: 367, name: "Tottenham Hotspur", logoURL: logo(367), shortName: "Spurs", code: "TOT")
    ]

    private static func club(_ id: Int) -> Club { league.first { $0.id == id } ?? Club(id: id, name: "?") }

    public static let players: [Player] = [
        Player(id: 159443, name: "Jordan Pickford", number: 1, position: .goalkeeper, age: 32, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 0, goals: 0, assists: 0, shots: 0, shotsOnTarget: 0, foulsCommitted: 0, foulsSuffered: 4, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 28, conceded: 10, shotsFaced: 0), heightCM: 185, weightKG: 77, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 7441, name: "Mark Travers", number: 12, position: .goalkeeper, age: 27, nationality: "Republic of Ireland", photoURL: nil, stats: PlayerStats(appearances: 0, subIns: 0, goals: 0, assists: 0, shots: 0, shotsOnTarget: 0, foulsCommitted: 0, foulsSuffered: 0, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 0, shotsFaced: 0), heightCM: 190, weightKG: 82, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/irl.png")),
        Player(id: 148515, name: "Tom King", number: 31, position: .goalkeeper, age: 31, nationality: "Wales", photoURL: nil, stats: PlayerStats(appearances: 0, subIns: 0, goals: 0, assists: 0, shots: 0, shotsOnTarget: 0, foulsCommitted: 0, foulsSuffered: 0, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 0, shotsFaced: 0), heightCM: 193, weightKG: 79, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/wal.png")),
        Player(id: 286965, name: "Jarrad Branthwaite", number: 4, position: .defender, age: 24, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 9, subIns: 0, goals: 0, assists: 0, shots: 6, shotsOnTarget: 4, foulsCommitted: 6, foulsSuffered: 8, offsides: 1, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 8, shotsFaced: 0), heightCM: 196, weightKG: 87, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 4946, name: "Michael Keane", number: 5, position: .defender, age: 33, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 3, subIns: 2, goals: 0, assists: 0, shots: 1, shotsOnTarget: 0, foulsCommitted: 1, foulsSuffered: 0, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 2, shotsFaced: 0), heightCM: 190, weightKG: 82, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 155226, name: "James Tarkowski", number: 6, position: .defender, age: 33, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 0, goals: 1, assists: 1, shots: 4, shotsOnTarget: 1, foulsCommitted: 6, foulsSuffered: 15, offsides: 1, yellow: 2, red: 0, ownGoals: 0, saves: 0, conceded: 10, shotsFaced: 0), heightCM: 185, weightKG: 81, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 283586, name: "Jake O'Brien", number: 15, position: .defender, age: 25, nationality: "Republic of Ireland", photoURL: nil, stats: PlayerStats(appearances: 6, subIns: 4, goals: 0, assists: 0, shots: 2, shotsOnTarget: 1, foulsCommitted: 2, foulsSuffered: 1, offsides: 1, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 2, shotsFaced: 0), heightCM: 198, weightKG: 92, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/irl.png")),
        Player(id: 262594, name: "Vitaliy Mykolenko", number: 16, position: .defender, age: 27, nationality: "Ukraine", photoURL: nil, stats: PlayerStats(appearances: 9, subIns: 0, goals: 0, assists: 1, shots: 2, shotsOnTarget: 1, foulsCommitted: 4, foulsSuffered: 11, offsides: 0, yellow: 2, red: 0, ownGoals: 0, saves: 0, conceded: 8, shotsFaced: 0), heightCM: 180, weightKG: 71, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/ukr.png")),
        Player(id: 214402, name: "Ainsley Maitland-Niles", number: 2, position: .midfielder, age: 29, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 5, subIns: 1, goals: 1, assists: 1, shots: 2, shotsOnTarget: 1, foulsCommitted: 2, foulsSuffered: 1, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 4, shotsFaced: 0), heightCM: 178, weightKG: 71, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 252389, name: "Kiernan Dewsbury-Hall", number: 8, position: .midfielder, age: 28, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 0, goals: 3, assists: 1, shots: 26, shotsOnTarget: 8, foulsCommitted: 3, foulsSuffered: 16, offsides: 1, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 10, shotsFaced: 0), heightCM: 178, weightKG: 79, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 172850, name: "Jack Grealish", number: 10, position: .midfielder, age: 31, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 5, subIns: 2, goals: 0, assists: 0, shots: 4, shotsOnTarget: 2, foulsCommitted: 2, foulsSuffered: 8, offsides: 2, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 4, shotsFaced: 0), heightCM: 180, weightKG: 77, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 178077, name: "Christian Nørgaard", number: 23, position: .midfielder, age: 32, nationality: "Denmark", photoURL: nil, stats: PlayerStats(appearances: 1, subIns: 1, goals: 0, assists: 0, shots: 0, shotsOnTarget: 0, foulsCommitted: 1, foulsSuffered: 0, offsides: 0, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 1, shotsFaced: 0), heightCM: 188, weightKG: 73, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/den.png")),
        Player(id: 302162, name: "Charly Alcaraz", number: 24, position: .midfielder, age: 23, nationality: "Argentina", photoURL: nil, stats: PlayerStats(appearances: 5, subIns: 5, goals: 0, assists: 0, shots: 4, shotsOnTarget: 1, foulsCommitted: 1, foulsSuffered: 1, offsides: 0, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 0, shotsFaced: 0), heightCM: 175, weightKG: 68, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/arg.png")),
        Player(id: 282978, name: "Hayden Hackney", number: 30, position: .midfielder, age: 24, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 9, subIns: 8, goals: 0, assists: 1, shots: 4, shotsOnTarget: 2, foulsCommitted: 4, foulsSuffered: 4, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 1, shotsFaced: 0), heightCM: 178, weightKG: 69, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 311963, name: "Merlin Röhl", number: 34, position: .midfielder, age: 24, nationality: "Germany", photoURL: nil, stats: PlayerStats(appearances: 7, subIns: 0, goals: 0, assists: 0, shots: 2, shotsOnTarget: 1, foulsCommitted: 5, foulsSuffered: 6, offsides: 0, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 7, shotsFaced: 0), heightCM: 193, weightKG: 74, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/ger.png")),
        Player(id: 276220, name: "James Garner", number: 37, position: .midfielder, age: 25, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 1, goals: 0, assists: 0, shots: 8, shotsOnTarget: 2, foulsCommitted: 10, foulsSuffered: 8, offsides: 0, yellow: 3, red: 0, ownGoals: 0, saves: 0, conceded: 9, shotsFaced: 0), heightCM: 185, weightKG: 78, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 378458, name: "Harrison Armstrong", number: 45, position: .midfielder, age: 19, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 0, goals: 0, assists: 1, shots: 9, shotsOnTarget: 3, foulsCommitted: 10, foulsSuffered: 7, offsides: 0, yellow: 3, red: 0, ownGoals: 0, saves: 0, conceded: 9, shotsFaced: 0), heightCM: 185, weightKG: 69, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 410322, name: "Malik Olayiwola", number: 76, position: .midfielder, age: 17, nationality: "England", photoURL: nil, stats: nil, heightCM: nil, weightKG: nil, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 392052, name: "Harvey Foster", number: 81, position: .midfielder, age: 19, nationality: "England", photoURL: nil, stats: nil, heightCM: nil, weightKG: nil, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 301166, name: "Thierno Barry", number: 11, position: .attacker, age: 26, nationality: "Guinea", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 0, goals: 6, assists: 1, shots: 36, shotsOnTarget: 15, foulsCommitted: 9, foulsSuffered: 15, offsides: 4, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 10, shotsFaced: 0), heightCM: 173, weightKG: 82, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/gui.png")),
        Player(id: 368864, name: "Tyrique George", number: 19, position: .attacker, age: 20, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 3, goals: 1, assists: 0, shots: 16, shotsOnTarget: 4, foulsCommitted: 3, foulsSuffered: 6, offsides: 3, yellow: 1, red: 0, ownGoals: 0, saves: 0, conceded: 8, shotsFaced: 0), heightCM: 180, weightKG: 74, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 340640, name: "Tyler Dibling", number: 20, position: .attacker, age: 20, nationality: "England", photoURL: nil, stats: PlayerStats(appearances: 4, subIns: 3, goals: 0, assists: 0, shots: 4, shotsOnTarget: 1, foulsCommitted: 2, foulsSuffered: 2, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 1, shotsFaced: 0), heightCM: 178, weightKG: 72, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/eng.png")),
        Player(id: 291307, name: "Brennan Johnson", number: 22, position: .attacker, age: 25, nationality: "Wales", photoURL: nil, stats: PlayerStats(appearances: 10, subIns: 5, goals: 0, assists: 0, shots: 5, shotsOnTarget: 0, foulsCommitted: 9, foulsSuffered: 3, offsides: 7, yellow: 2, red: 0, ownGoals: 0, saves: 0, conceded: 5, shotsFaced: 0), heightCM: 185, weightKG: 73, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/wal.png")),
        Player(id: 367559, name: "Braiden Graham", number: 58, position: .attacker, age: 19, nationality: "Northern Ireland", photoURL: nil, stats: PlayerStats(appearances: 0, subIns: 0, goals: 0, assists: 0, shots: 0, shotsOnTarget: 0, foulsCommitted: 0, foulsSuffered: 0, offsides: 0, yellow: 0, red: 0, ownGoals: 0, saves: 0, conceded: 0, shotsFaced: 0), heightCM: 175, weightKG: 67, flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/nir.png"))
    ]

    public static let standings: [StandingRow] = [
        StandingRow(rank: 1, club: club(359), played: 10, won: 9, drawn: 0, lost: 1, goalsFor: 15, goalsAgainst: 5, points: 27, form: "", note: "Champions League"),
        StandingRow(rank: 2, club: club(331), played: 10, won: 7, drawn: 1, lost: 2, goalsFor: 26, goalsAgainst: 7, points: 22, form: "", note: "Champions League"),
        StandingRow(rank: 3, club: club(382), played: 10, won: 7, drawn: 0, lost: 3, goalsFor: 21, goalsAgainst: 13, points: 21, form: "", note: "Champions League"),
        StandingRow(rank: 4, club: club(364), played: 10, won: 5, drawn: 3, lost: 2, goalsFor: 14, goalsAgainst: 10, points: 18, form: "", note: "Champions League"),
        StandingRow(rank: 5, club: club(363), played: 10, won: 5, drawn: 1, lost: 4, goalsFor: 19, goalsAgainst: 16, points: 16, form: "", note: "Europa League"),
        StandingRow(rank: 6, club: club(368), played: 10, won: 4, drawn: 4, lost: 2, goalsFor: 12, goalsAgainst: 10, points: 16, form: "", note: nil),
        StandingRow(rank: 7, club: club(349), played: 10, won: 4, drawn: 3, lost: 3, goalsFor: 16, goalsAgainst: 14, points: 15, form: "", note: nil),
        StandingRow(rank: 8, club: club(337), played: 10, won: 3, drawn: 5, lost: 2, goalsFor: 16, goalsAgainst: 11, points: 14, form: "", note: nil),
        StandingRow(rank: 9, club: club(357), played: 10, won: 3, drawn: 5, lost: 2, goalsFor: 10, goalsAgainst: 8, points: 14, form: "", note: nil),
        StandingRow(rank: 10, club: club(362), played: 10, won: 3, drawn: 4, lost: 3, goalsFor: 14, goalsAgainst: 17, points: 13, form: "", note: nil),
        StandingRow(rank: 11, club: club(367), played: 10, won: 3, drawn: 3, lost: 4, goalsFor: 10, goalsAgainst: 11, points: 12, form: "", note: nil),
        StandingRow(rank: 12, club: club(361), played: 10, won: 3, drawn: 3, lost: 4, goalsFor: 13, goalsAgainst: 16, points: 12, form: "", note: nil),
        StandingRow(rank: 13, club: club(306), played: 10, won: 2, drawn: 5, lost: 3, goalsFor: 11, goalsAgainst: 11, points: 11, form: "", note: nil),
        StandingRow(rank: 14, club: club(373), played: 10, won: 3, drawn: 2, lost: 5, goalsFor: 15, goalsAgainst: 20, points: 11, form: "", note: nil),
        StandingRow(rank: 15, club: club(370), played: 10, won: 2, drawn: 4, lost: 4, goalsFor: 10, goalsAgainst: 12, points: 10, form: "", note: nil),
        StandingRow(rank: 16, club: club(393), played: 10, won: 2, drawn: 3, lost: 5, goalsFor: 9, goalsAgainst: 13, points: 9, form: "", note: nil),
        StandingRow(rank: 17, club: club(388), played: 10, won: 3, drawn: 0, lost: 7, goalsFor: 10, goalsAgainst: 19, points: 9, form: "", note: nil),
        StandingRow(rank: 18, club: club(360), played: 10, won: 1, drawn: 5, lost: 4, goalsFor: 14, goalsAgainst: 19, points: 8, form: "", note: "Relegation"),
        StandingRow(rank: 19, club: club(366), played: 10, won: 2, drawn: 2, lost: 6, goalsFor: 8, goalsAgainst: 17, points: 8, form: "", note: "Relegation"),
        StandingRow(rank: 20, club: club(384), played: 10, won: 2, drawn: 1, lost: 7, goalsFor: 10, goalsAgainst: 24, points: 7, form: "", note: "Relegation")
    ]

    public static let clubs: [ClubInfo] = league.map { ClubInfo(club: $0, code: $0.code, country: "England") }

    private static func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text) ?? Date() }

    public static let matches: [Match] = [
        Match(id: 401878771, kickoff: date("2026-10-17T11:30:00Z"), competition: "Premier League", round: "", venue: "Hill Dickinson Stadium", home: club(368), away: club(363), homeGoals: 0, awayGoals: 2, phase: .finished, statusText: "Full Time", elapsed: nil),
        Match(id: 401878768, kickoff: date("2026-10-24T14:00:00Z"), competition: "Premier League", round: "", venue: "Emirates Stadium", home: club(359), away: club(368), homeGoals: 2, awayGoals: 0, phase: .finished, statusText: "Full Time", elapsed: nil),
        Match(id: 401878762, kickoff: date("2026-11-02T20:00:00Z"), competition: "Premier League", round: "", venue: "St. James' Park", home: club(361), away: club(368), homeGoals: 0, awayGoals: 1, phase: .finished, statusText: "Full Time", elapsed: nil),
        Match(id: 401879242, kickoff: date("2026-11-06T20:00:00Z"), competition: "Premier League", round: "", venue: "Hill Dickinson Stadium", home: club(368), away: club(388), homeGoals: 3, awayGoals: 1, phase: .finished, statusText: "Full Time", elapsed: nil),
        Match(id: 401879237, kickoff: date("2026-11-23T20:00:00Z"), competition: "Premier League", round: "", venue: "Gtech Community Stadium", home: club(337), away: club(368), homeGoals: nil, awayGoals: nil, phase: .upcoming, statusText: "Scheduled", elapsed: nil),
        Match(id: 401879229, kickoff: date("2026-11-29T12:00:00Z"), competition: "Premier League", round: "", venue: "Hill Dickinson Stadium", home: club(368), away: club(364), homeGoals: nil, awayGoals: nil, phase: .upcoming, statusText: "Scheduled", elapsed: nil),
        Match(id: 401878751, kickoff: date("2026-12-02T20:15:00Z"), competition: "Premier League", round: "", venue: "Villa Park", home: club(362), away: club(368), homeGoals: nil, awayGoals: nil, phase: .upcoming, statusText: "Scheduled", elapsed: nil)
    ]

    public static let news: [NewsItem] = []
}

public struct MockFootballService: FootballService {
    public init() {}
    public var homeTeamID: Int { EvertonInfo.teamID }
    public func matches() async throws -> [Match] { Sample.matches }
    public func detail(of match: Match) async throws -> MatchDetail { MatchDetail(match: match, stats: [], lineups: [], events: []) }
    public func squad(of clubID: Int) async throws -> [Player] { clubID == EvertonInfo.teamID ? Sample.players : [] }
    public func clubs() async throws -> [ClubInfo] { Sample.clubs }
    public func standings() async throws -> [StandingRow] { Sample.standings }
    public func diagnostics() async -> DataReport {
        DataReport(seasonFound: true, fixtureCount: Sample.matches.count, squadCount: Sample.players.count,
                   missingNumbers: Sample.players.filter { $0.number == nil }.count, missingPhotos: Sample.players.count,
                   nextMatchDate: Sample.matches.nextMatch()?.kickoff,
                   errors: ["오프라인 스냅샷(\(Sample.snapshotDate))입니다. 네트워크가 연결되면 실시간 데이터를 불러옵니다."],
                   source: "오프라인 스냅샷", seasonName: "2026-27 English Premier League",
                   unavailable: ["선수 평점", "패스·태클·드리블·키패스·출전 시간", "선수 사진"])
    }
}

public struct MockNewsService: NewsService {
    public init() {}
    public func headlines() async throws -> [NewsItem] { Sample.news }
}
