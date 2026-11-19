import Foundation

public enum MatchEventKind: String, Codable, Sendable {
    case goal, ownGoal, missedPenalty, yellow, red, substitution, var_, other
}

public struct MatchEvent: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let minute: Int
    public let extra: Int?
    public let clubID: Int
    public let player: String
    public let assist: String?
    public let kind: MatchEventKind

    public init(id: Int, minute: Int, extra: Int?, clubID: Int, player: String, assist: String?, kind: MatchEventKind) {
        self.id = id
        self.minute = minute
        self.extra = extra
        self.clubID = clubID
        self.player = player
        self.assist = assist
        self.kind = kind
    }

    public var minuteText: String { extra.map { "\(minute)+\($0)'" } ?? "\(minute)'" }

    public var symbol: String {
        switch kind {
        case .goal: return "⚽️"
        case .ownGoal: return "🥅"
        case .missedPenalty: return "❌"
        case .yellow: return "🟨"
        case .red: return "🟥"
        case .substitution: return "🔁"
        case .var_: return "📺"
        case .other: return "•"
        }
    }

    /// 타임라인에 보여 줄 가치가 있는 이벤트인지 (교체는 제외).
    public var isKey: Bool { kind != .substitution && kind != .other }
}

public struct StandingRow: Hashable, Codable, Sendable, Identifiable {
    public var id: Int { club.id }
    public let rank: Int
    public let club: Club
    public let played: Int
    public let won: Int
    public let drawn: Int
    public let lost: Int
    public let goalsFor: Int
    public let goalsAgainst: Int
    public let points: Int
    public let form: String
    public let note: String?

    public init(rank: Int, club: Club, played: Int, won: Int, drawn: Int, lost: Int,
                goalsFor: Int, goalsAgainst: Int, points: Int, form: String, note: String?) {
        self.rank = rank
        self.club = club
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.points = points
        self.form = form
        self.note = note
    }

    public var goalDifference: Int { goalsFor - goalsAgainst }

    /// API 의 description 문자열로 구간을 나눈다 (챔피언스리그/유로파/강등).
    public enum Zone: Sendable { case champions, europa, conference, relegation, none }

    public var zone: Zone {
        let text = (note ?? "").lowercased()
        if text.contains("relegation") { return .relegation }
        if text.contains("champions") { return .champions }
        if text.contains("europa league") { return .europa }
        if text.contains("conference") { return .conference }
        return .none
    }
}

public struct DataReport: Hashable, Codable, Sendable {
    public var checkedAt: Date
    public var expectedSeason: Int
    public var seasonFound: Bool
    public var seasonStart: String?
    public var seasonEnd: String?
    public var fixtureCount: Int
    public var squadCount: Int
    public var missingNumbers: Int
    public var missingPhotos: Int
    public var nextMatchDate: Date?
    public var errors: [String]
    /// 데이터 출처 이름과 출처가 표기한 시즌 이름.
    public var source: String
    public var seasonName: String?
    /// 출처가 제공하지 않아 표시하지 못하는 항목.
    public var unavailable: [String]

    public init(checkedAt: Date = Date(), expectedSeason: Int = EvertonInfo.season, seasonFound: Bool = false,
                seasonStart: String? = nil, seasonEnd: String? = nil, fixtureCount: Int = 0, squadCount: Int = 0,
                missingNumbers: Int = 0, missingPhotos: Int = 0, nextMatchDate: Date? = nil, errors: [String] = [],
                source: String = "", seasonName: String? = nil, unavailable: [String] = []) {
        self.source = source
        self.seasonName = seasonName
        self.unavailable = unavailable
        self.checkedAt = checkedAt
        self.expectedSeason = expectedSeason
        self.seasonFound = seasonFound
        self.seasonStart = seasonStart
        self.seasonEnd = seasonEnd
        self.fixtureCount = fixtureCount
        self.squadCount = squadCount
        self.missingNumbers = missingNumbers
        self.missingPhotos = missingPhotos
        self.nextMatchDate = nextMatchDate
        self.errors = errors
    }

    public struct Check: Identifiable, Sendable {
        public enum Level: Sendable { case ok, warning, problem }
        public let id = UUID()
        public let title: String
        public let detail: String
        public let level: Level
    }

    /// 사람이 읽을 수 있는 점검 항목. 시즌·일정·스쿼드가 기대와 맞는지 한눈에 보여 준다.
    public var checks: [Check] {
        var list: [Check] = []
        let label = "\(expectedSeason)-\(String(expectedSeason + 1).suffix(2))"
        if seasonFound {
            let years = [seasonStart, seasonEnd].compactMap { $0?.prefix(4) }.joined(separator: " ~ ")
            let detail = seasonName.map { "출처 시즌 표기: \($0)" } ?? (years.isEmpty ? "출처에서 확인됨" : "시즌 기간 \(years)")
            list.append(Check(title: "\(label) 시즌", detail: detail, level: .ok))
        } else {
            list.append(Check(title: "\(label) 시즌", detail: "출처에서 해당 시즌을 찾지 못했습니다.", level: .problem))
        }
        list.append(Check(title: "경기 일정", detail: "\(fixtureCount)경기 (정규 시즌 38경기 + 컵대회)",
                          level: fixtureCount >= 38 ? .ok : (fixtureCount == 0 ? .problem : .warning)))
        list.append(Check(title: "스쿼드", detail: "\(squadCount)명",
                          level: squadCount >= 18 ? .ok : (squadCount == 0 ? .problem : .warning)))
        if missingNumbers > 0 {
            list.append(Check(title: "등번호", detail: "\(missingNumbers)명의 번호가 없습니다 (API 반영 지연일 수 있음).", level: .warning))
        }
        if missingPhotos > 0 {
            list.append(Check(title: "선수 사진", detail: "\(missingPhotos)명의 사진이 없습니다.", level: .warning))
        }
        if let nextMatchDate {
            list.append(Check(title: "다음 경기", detail: "\(Fmt.day(nextMatchDate)) \(Fmt.time(nextMatchDate))", level: .ok))
        }
        if !unavailable.isEmpty {
            list.append(Check(title: "제공되지 않는 항목", detail: unavailable.joined(separator: " · ") + " (출처 한계, 임의 값으로 채우지 않음)", level: .warning))
        }
        for error in errors { list.append(Check(title: "오류", detail: error, level: .problem)) }
        return list
    }
}

public struct ClubInfo: Hashable, Codable, Sendable, Identifiable {
    public var id: Int { club.id }
    public let club: Club
    public let code: String?
    public let country: String?
    public let founded: Int?
    public let venueName: String?
    public let city: String?
    public let capacity: Int?
    public let venueImageURL: URL?

    public init(club: Club, code: String? = nil, country: String? = nil, founded: Int? = nil,
                venueName: String? = nil, city: String? = nil, capacity: Int? = nil, venueImageURL: URL? = nil) {
        self.club = club
        self.code = code
        self.country = country
        self.founded = founded
        self.venueName = venueName
        self.city = city
        self.capacity = capacity
        self.venueImageURL = venueImageURL
    }
}
