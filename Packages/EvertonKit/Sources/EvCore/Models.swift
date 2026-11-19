import Foundation

public enum EvertonInfo {
    /// ESPN 의 에버턴 ID. 앱의 기본 데이터 출처.
    public static let teamID = 368
    /// API-Football 의 에버턴 ID (키를 넣었을 때만 사용).
    public static let apiFootballTeamID = 45
    public static let leagueID = 39
    public static let season = 2026
    public static let teamName = "Everton"

    /// 출처에 관계없이 에버턴인지 확인한다.
    public static func isEverton(_ id: Int) -> Bool { id == teamID || id == apiFootballTeamID }
}

public struct Club: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let logoURL: URL?
    /// 표에서 쓰는 짧은 이름 ("Brighton & Hove Albion" -> "Brighton").
    public let shortName: String?
    /// 3글자 약어 ("EVE").
    public let code: String?

    public init(id: Int, name: String, logoURL: URL? = nil, shortName: String? = nil, code: String? = nil) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.shortName = shortName
        self.code = code
    }

    public var display: String { shortName ?? name }
    public var abbreviation: String { code ?? String(name.prefix(3)).uppercased() }
}

public enum MatchPhase: String, Codable, Sendable {
    case upcoming, live, finished, other
}

public enum MatchResult: String, Codable, Sendable {
    case win, draw, loss

    public var letter: String {
        switch self {
        case .win: return "W"
        case .draw: return "D"
        case .loss: return "L"
        }
    }
}

public struct Match: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let kickoff: Date
    public let competition: String
    public let round: String
    public let venue: String?
    public let home: Club
    public let away: Club
    public let homeGoals: Int?
    public let awayGoals: Int?
    public let phase: MatchPhase
    public let statusText: String
    public let elapsed: Int?

    public init(id: Int, kickoff: Date, competition: String, round: String, venue: String?,
                home: Club, away: Club, homeGoals: Int?, awayGoals: Int?,
                phase: MatchPhase, statusText: String, elapsed: Int?) {
        self.id = id
        self.kickoff = kickoff
        self.competition = competition
        self.round = round
        self.venue = venue
        self.home = home
        self.away = away
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
        self.phase = phase
        self.statusText = statusText
        self.elapsed = elapsed
    }

    /// teamID 를 주지 않으면 에버턴(출처와 무관하게) 기준.
    public func isHome(_ teamID: Int? = nil) -> Bool {
        teamID.map { home.id == $0 } ?? EvertonInfo.isEverton(home.id)
    }

    public func opponent(of teamID: Int? = nil) -> Club {
        isHome(teamID) ? away : home
    }

    public func result(for teamID: Int? = nil) -> MatchResult? {
        guard phase == .finished, let h = homeGoals, let a = awayGoals else { return nil }
        let mine = isHome(teamID) ? h : a
        let theirs = isHome(teamID) ? a : h
        if mine > theirs { return .win }
        if mine == theirs { return .draw }
        return .loss
    }

    public var scoreText: String {
        guard let h = homeGoals, let a = awayGoals else { return "-" }
        return "\(h) : \(a)"
    }
}

public enum Position: String, Codable, CaseIterable, Sendable {
    case goalkeeper, defender, midfielder, attacker

    public init(apiName: String?) {
        switch apiName?.lowercased() {
        case "goalkeeper", "g": self = .goalkeeper
        case "defender", "d": self = .defender
        case "midfielder", "m": self = .midfielder
        default: self = .attacker
        }
    }

    public var short: String {
        switch self {
        case .goalkeeper: return "GK"
        case .defender: return "DF"
        case .midfielder: return "MF"
        case .attacker: return "FW"
        }
    }

    public var title: String {
        switch self {
        case .goalkeeper: return "골키퍼"
        case .defender: return "수비수"
        case .midfielder: return "미드필더"
        case .attacker: return "공격수"
        }
    }
}

/// 시즌 누적 기록. 출처(ESPN)가 주지 않는 항목은 nil 이며, 임의의 값으로 채우지 않는다.
public struct PlayerStats: Hashable, Codable, Sendable {
    public var appearances: Int
    public var subIns: Int
    public var goals: Int
    public var assists: Int
    public var shots: Int
    public var shotsOnTarget: Int
    public var foulsCommitted: Int
    public var foulsSuffered: Int
    public var offsides: Int
    public var yellow: Int
    public var red: Int
    public var ownGoals: Int
    public var saves: Int
    public var conceded: Int
    public var shotsFaced: Int
    // API-Football 처럼 더 자세한 출처에서만 채워지는 값
    public var minutes: Int?
    public var rating: Double?
    public var passAccuracy: Int?
    public var keyPasses: Int?
    public var tackles: Int?
    public var dribbles: Int?

    public init(appearances: Int = 0, subIns: Int = 0, goals: Int = 0, assists: Int = 0, shots: Int = 0,
                shotsOnTarget: Int = 0, foulsCommitted: Int = 0, foulsSuffered: Int = 0, offsides: Int = 0,
                yellow: Int = 0, red: Int = 0, ownGoals: Int = 0, saves: Int = 0, conceded: Int = 0,
                shotsFaced: Int = 0, minutes: Int? = nil, rating: Double? = nil, passAccuracy: Int? = nil,
                keyPasses: Int? = nil, tackles: Int? = nil, dribbles: Int? = nil) {
        self.appearances = appearances
        self.subIns = subIns
        self.goals = goals
        self.assists = assists
        self.shots = shots
        self.shotsOnTarget = shotsOnTarget
        self.foulsCommitted = foulsCommitted
        self.foulsSuffered = foulsSuffered
        self.offsides = offsides
        self.yellow = yellow
        self.red = red
        self.ownGoals = ownGoals
        self.saves = saves
        self.conceded = conceded
        self.shotsFaced = shotsFaced
        self.minutes = minutes
        self.rating = rating
        self.passAccuracy = passAccuracy
        self.keyPasses = keyPasses
        self.tackles = tackles
        self.dribbles = dribbles
    }

    /// 골 + 도움.
    public var contribution: Int { goals + assists }
}

public struct Player: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let number: Int?
    public let position: Position
    public let age: Int?
    public let nationality: String?
    public let photoURL: URL?
    public var stats: PlayerStats?
    public var heightCM: Int?
    public var weightKG: Int?
    public var birthDate: Date?
    public var birthPlace: String?
    public var flagURL: URL?

    public init(id: Int, name: String, number: Int?, position: Position, age: Int?,
                nationality: String? = nil, photoURL: URL?, stats: PlayerStats? = nil,
                heightCM: Int? = nil, weightKG: Int? = nil, birthDate: Date? = nil, birthPlace: String? = nil,
                flagURL: URL? = nil) {
        self.flagURL = flagURL
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.id = id
        self.name = name
        self.number = number
        self.position = position
        self.age = age
        self.nationality = nationality
        self.photoURL = photoURL
        self.stats = stats
    }

    /// 성만 보여 줄 때 사용 ("J. Pickford" -> "Pickford").
    public var shortName: String {
        name.split(separator: " ").last.map(String.init) ?? name
    }
}

public struct LineupPlayer: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let number: Int?
    public let position: String?
    /// API 의 "행:열" 표기 (1:1 = 골키퍼). 교체 선수는 nil.
    public let grid: String?
    public var rating: Double?
    public var photoURL: URL?

    public init(id: Int, name: String, number: Int?, position: String?, grid: String?,
                rating: Double? = nil, photoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.position = position
        self.grid = grid
        self.rating = rating
        self.photoURL = photoURL
    }

    public var shortName: String {
        name.split(separator: " ").last.map(String.init) ?? name
    }
}

public struct TeamLineup: Hashable, Codable, Sendable {
    public let club: Club
    public let formation: String?
    public let starters: [LineupPlayer]
    public let substitutes: [LineupPlayer]

    public init(club: Club, formation: String?, starters: [LineupPlayer], substitutes: [LineupPlayer]) {
        self.club = club
        self.formation = formation
        self.starters = starters
        self.substitutes = substitutes
    }
}

public struct StatLine: Hashable, Codable, Sendable, Identifiable {
    public var id: String { label }
    public let label: String
    public let home: Double
    public let away: Double
    public let isPercent: Bool

    public init(label: String, home: Double, away: Double, isPercent: Bool) {
        self.label = label
        self.home = home
        self.away = away
        self.isPercent = isPercent
    }
}

public struct MatchDetail: Hashable, Codable, Sendable {
    public let match: Match
    public let stats: [StatLine]
    public let lineups: [TeamLineup]
    public let events: [MatchEvent]

    public init(match: Match, stats: [StatLine], lineups: [TeamLineup], events: [MatchEvent] = []) {
        self.match = match
        self.stats = stats
        self.lineups = lineups
        self.events = events
    }
}

public struct NewsItem: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let summary: String
    public let link: URL?
    public let date: Date?
    public let imageURL: URL?

    public init(id: String, title: String, summary: String, link: URL?, date: Date?, imageURL: URL?) {
        self.id = id
        self.title = title
        self.summary = summary
        self.link = link
        self.date = date
        self.imageURL = imageURL
    }
}
