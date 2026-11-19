import Foundation

// ESPN 공개 API 응답. 형식이 바뀌어도 앱이 죽지 않도록 거의 모든 필드를 옵셔널로 둔다.

/// "368" 처럼 문자열이거나 368 처럼 숫자로 오는 ID.
struct ESPNID: Decodable, Hashable {
    let text: String
    var int: Int? { Int(text) }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { text = s }
        else if let i = try? c.decode(Int.self) { text = String(i) }
        else { text = "" }
    }
}

/// 점수는 "2" 처럼 문자열이거나 {"displayValue":"2"} 객체로 온다.
struct ESPNScore: Decodable {
    let value: Int?

    private enum Keys: String, CodingKey { case displayValue, value }

    init(from decoder: Decoder) throws {
        if let c = try? decoder.singleValueContainer(), let text = try? c.decode(String.self) {
            value = Int(text)
        } else if let c = try? decoder.singleValueContainer(), let number = try? c.decode(Int.self) {
            value = number
        } else if let k = try? decoder.container(keyedBy: Keys.self) {
            if let text = try? k.decode(String.self, forKey: .displayValue) { value = Int(text) }
            else if let number = try? k.decode(Double.self, forKey: .value) { value = Int(number) }
            else { value = nil }
        } else {
            value = nil
        }
    }
}

struct ESPNLogo: Decodable { let href: String? }

struct ESPNTeam: Decodable {
    let id: ESPNID
    let displayName: String?
    let shortDisplayName: String?
    let abbreviation: String?
    let logos: [ESPNLogo]?
    let logo: String?
    let color: String?
}

struct ESPNSeason: Decodable {
    let year: Int?
    let displayName: String?
}

// MARK: 일정

struct ESPNSchedule: Decodable {
    let events: [ESPNEvent]?
    let season: ESPNSeason?
}

struct ESPNEvent: Decodable {
    let id: ESPNID
    let date: String
    let competitions: [ESPNCompetition]?
}

struct ESPNCompetition: Decodable {
    struct Venue: Decodable { let fullName: String? }
    struct Competitor: Decodable {
        let homeAway: String?
        let team: ESPNTeam
        let score: ESPNScore?
    }
    struct Status: Decodable {
        struct Kind: Decodable { let state: String?; let description: String? }
        let type: Kind?
    }
    let venue: Venue?
    let competitors: [Competitor]?
    let status: Status?
}

// MARK: 로스터

struct ESPNRoster: Decodable {
    struct Coach: Decodable { let firstName: String?; let lastName: String? }
    let athletes: [ESPNAthlete]?
    let coach: [Coach]?
    let season: ESPNSeason?
}

struct ESPNAthlete: Decodable {
    struct Position: Decodable { let abbreviation: String?; let name: String? }
    struct Flag: Decodable { let href: String? }
    struct Place: Decodable { let city: String?; let state: String?; let country: String? }
    struct Stat: Decodable { let name: String?; let value: Double? }
    struct Category: Decodable { let stats: [Stat]? }
    struct Splits: Decodable { let categories: [Category]? }
    struct Statistics: Decodable { let splits: Splits? }

    let id: ESPNID
    let fullName: String?
    let displayName: String?
    let shortName: String?
    let jersey: String?
    let age: Int?
    let height: Double?          // 인치
    let weight: Double?          // 파운드
    let dateOfBirth: String?
    let citizenship: String?
    let flag: Flag?
    let position: Position?
    let birthPlace: Place?
    let statistics: Statistics?
}

// MARK: 구단 목록 · 순위

struct ESPNTeams: Decodable {
    struct Entry: Decodable { let team: ESPNTeam }
    struct League: Decodable { let teams: [Entry]? }
    struct Sport: Decodable { let leagues: [League]? }
    let sports: [Sport]?
}

struct ESPNStandings: Decodable {
    struct Stat: Decodable { let name: String?; let value: Double? }
    struct Note: Decodable { let description: String? }
    struct Entry: Decodable {
        let team: ESPNTeam
        let note: Note?
        let stats: [Stat]?
    }
    struct Table: Decodable { let entries: [Entry]? }
    struct Child: Decodable { let standings: Table? }
    let children: [Child]?
}

// MARK: 경기 요약

struct ESPNSummary: Decodable {
    struct BoxStat: Decodable { let name: String?; let displayValue: String? }
    struct BoxTeam: Decodable {
        struct Ref: Decodable { let id: ESPNID }
        let team: Ref
        let statistics: [BoxStat]?
    }
    struct Box: Decodable { let teams: [BoxTeam]? }

    struct RosterEntry: Decodable {
        struct Athlete: Decodable { let id: ESPNID?; let displayName: String?; let shortName: String? }
        struct Position: Decodable { let abbreviation: String? }
        let starter: Bool?
        let jersey: String?
        let formationPlace: String?
        let position: Position?
        let athlete: Athlete?
    }
    struct Side: Decodable {
        let homeAway: String?
        let formation: String?
        let team: ESPNTeam?
        let roster: [RosterEntry]?
    }

    struct KeyEvent: Decodable {
        struct Kind: Decodable { let type: String?; let text: String? }
        struct Clock: Decodable { let displayValue: String? }
        struct Ref: Decodable { let id: ESPNID }
        struct Participant: Decodable {
            struct Athlete: Decodable { let displayName: String? }
            let athlete: Athlete?
        }
        let id: ESPNID?
        let type: Kind?
        let clock: Clock?
        let team: Ref?
        let participants: [Participant]?
    }

    let boxscore: Box?
    let rosters: [Side]?
    let keyEvents: [KeyEvent]?
}
