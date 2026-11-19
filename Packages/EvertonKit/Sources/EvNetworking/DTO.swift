import Foundation

/// API-Football 은 값이 숫자·문자열("58%")·null 로 섞여 나온다.
struct FlexNumber: Decodable {
    let value: Double?
    let isPercent: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            isPercent = false
        } else if let number = try? container.decode(Double.self) {
            value = number
            isPercent = false
        } else if let text = try? container.decode(String.self) {
            isPercent = text.contains("%")
            value = Double(text.trimmingCharacters(in: CharacterSet(charactersIn: "% ")))
        } else {
            value = nil
            isPercent = false
        }
    }
}

struct Paging: Decodable {
    let current: Int?
    let total: Int?
}

/// errors 는 비어 있으면 [], 있으면 {키: 메시지} 로 오기 때문에 따로 처리한다.
struct Envelope<T: Decodable>: Decodable {
    let response: T
    let paging: Paging?
    let errorMessage: String?

    private enum Keys: String, CodingKey { case response, paging, errors }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        paging = try? c.decode(Paging.self, forKey: .paging)
        if let dict = try? c.decode([String: String].self, forKey: .errors), let first = dict.values.first {
            errorMessage = first
        } else {
            errorMessage = nil
        }
        response = try c.decode(T.self, forKey: .response)
    }
}

struct TeamDTO: Decodable {
    let id: Int
    let name: String
    let logo: String?
}

struct FixtureDTO: Decodable {
    struct Fixture: Decodable {
        struct Status: Decodable { let short: String?; let long: String?; let elapsed: Int? }
        struct Venue: Decodable { let name: String? }
        let id: Int
        let date: String
        let status: Status
        let venue: Venue?
    }
    struct League: Decodable { let name: String?; let round: String? }
    struct Teams: Decodable { let home: TeamDTO; let away: TeamDTO }
    struct Goals: Decodable { let home: Int?; let away: Int? }

    let fixture: Fixture
    let league: League
    let teams: Teams
    let goals: Goals
}

struct StatisticsDTO: Decodable {
    struct Entry: Decodable { let type: String; let value: FlexNumber? }
    let team: TeamDTO
    let statistics: [Entry]
}

struct LineupDTO: Decodable {
    struct Slot: Decodable {
        struct Person: Decodable {
            let id: Int?
            let name: String?
            let number: Int?
            let pos: String?
            let grid: String?
        }
        let player: Person
    }
    let team: TeamDTO
    let formation: String?
    let startXI: [Slot]
    let substitutes: [Slot]
}

struct FixturePlayersDTO: Decodable {
    struct Entry: Decodable {
        struct Person: Decodable { let id: Int; let name: String?; let photo: String? }
        struct Stat: Decodable {
            struct Games: Decodable { let rating: FlexNumber? }
            let games: Games?
        }
        let player: Person
        let statistics: [Stat]
    }
    let team: TeamDTO
    let players: [Entry]
}

struct SquadDTO: Decodable {
    struct Member: Decodable {
        let id: Int
        let name: String
        let age: Int?
        let number: Int?
        let position: String?
        let photo: String?
    }
    let players: [Member]
}

struct SeasonPlayerDTO: Decodable {
    struct Person: Decodable {
        struct Birth: Decodable { let date: String?; let place: String? }
        let id: Int
        let name: String
        let age: Int?
        let nationality: String?
        let photo: String?
        let height: String?
        let weight: String?
        let birth: Birth?
    }
    struct Stat: Decodable {
        struct League: Decodable { let id: Int? }
        struct Games: Decodable {
            let appearences: Int?
            let minutes: Int?
            let rating: FlexNumber?
            let position: String?
        }
        struct Goals: Decodable { let total: Int?; let assists: Int?; let conceded: Int?; let saves: Int? }
        struct Shots: Decodable { let total: Int?; let on: Int? }
        struct Passes: Decodable { let total: Int?; let key: Int?; let accuracy: FlexNumber? }
        struct Tackles: Decodable { let total: Int? }
        struct Dribbles: Decodable { let success: Int? }
        struct Cards: Decodable { let yellow: Int?; let red: Int? }

        let league: League?
        let games: Games?
        let goals: Goals?
        let shots: Shots?
        let passes: Passes?
        let tackles: Tackles?
        let dribbles: Dribbles?
        let cards: Cards?
    }
    let player: Person
    let statistics: [Stat]
}

struct EventDTO: Decodable {
    struct Time: Decodable { let elapsed: Int?; let extra: Int? }
    struct Person: Decodable { let id: Int?; let name: String? }
    let time: Time
    let team: TeamDTO
    let player: Person?
    let assist: Person?
    let type: String?
    let detail: String?
}

struct StandingsDTO: Decodable {
    struct League: Decodable {
        let standings: [[Row]]
    }
    struct Row: Decodable {
        struct Record: Decodable {
            struct Goals: Decodable { let `for`: Int?; let against: Int? }
            let played: Int?
            let win: Int?
            let draw: Int?
            let lose: Int?
            let goals: Goals?
        }
        let rank: Int
        let team: TeamDTO
        let points: Int?
        let form: String?
        let description: String?
        let all: Record?
    }
    let league: League
}

struct LeagueInfoDTO: Decodable {
    struct Season: Decodable {
        let year: Int
        let start: String?
        let end: String?
        let current: Bool?
    }
    let seasons: [Season]
}

struct TeamEntryDTO: Decodable {
    struct Team: Decodable {
        let id: Int
        let name: String
        let code: String?
        let country: String?
        let founded: Int?
        let logo: String?
    }
    struct Venue: Decodable {
        let name: String?
        let city: String?
        let capacity: Int?
        let image: String?
    }
    let team: Team
    let venue: Venue?
}
