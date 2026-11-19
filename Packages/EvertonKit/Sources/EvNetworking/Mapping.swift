import Foundation
import EvCore

enum Mapping {
    private static let isoFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(_ text: String) -> Date? { isoFull.date(from: text) }

    static func club(_ dto: TeamDTO) -> Club {
        Club(id: dto.id, name: dto.name, logoURL: dto.logo.flatMap(URL.init(string:)))
    }

    static func phase(_ short: String?) -> MatchPhase {
        switch short ?? "" {
        case "NS", "TBD": return .upcoming
        case "1H", "HT", "2H", "ET", "BT", "P", "LIVE", "INT": return .live
        case "FT", "AET", "PEN": return .finished
        default: return .other
        }
    }

    static func match(_ dto: FixtureDTO) -> Match? {
        guard let kickoff = date(dto.fixture.date) else { return nil }
        return Match(
            id: dto.fixture.id, kickoff: kickoff,
            competition: dto.league.name ?? "", round: dto.league.round ?? "",
            venue: dto.fixture.venue?.name,
            home: club(dto.teams.home), away: club(dto.teams.away),
            homeGoals: dto.goals.home, awayGoals: dto.goals.away,
            phase: phase(dto.fixture.status.short),
            statusText: dto.fixture.status.long ?? "",
            elapsed: dto.fixture.status.elapsed)
    }

    private static let statLabels: [String: String] = [
        "Ball Possession": "점유율",
        "Total Shots": "슈팅",
        "Shots on Goal": "유효슈팅",
        "Shots off Goal": "빗나간 슈팅",
        "Blocked Shots": "차단된 슈팅",
        "Shots insidebox": "박스 안 슈팅",
        "Shots outsidebox": "박스 밖 슈팅",
        "Corner Kicks": "코너킥",
        "Offsides": "오프사이드",
        "Fouls": "파울",
        "Yellow Cards": "경고",
        "Red Cards": "퇴장",
        "Goalkeeper Saves": "선방",
        "Total passes": "패스",
        "Passes accurate": "정확한 패스",
        "Passes %": "패스 성공률",
        "expected_goals": "기대 득점(xG)",
    ]

    static func statLines(_ list: [StatisticsDTO], homeID: Int) -> [StatLine] {
        guard let home = list.first(where: { $0.team.id == homeID }) ?? list.first,
              let away = list.first(where: { $0.team.id != home.team.id }) else { return [] }
        var awayValues: [String: FlexNumber] = [:]
        for entry in away.statistics { if let v = entry.value { awayValues[entry.type] = v } }
        return home.statistics.compactMap { entry in
            let h = entry.value?.value ?? 0
            let a = awayValues[entry.type]?.value ?? 0
            let percent = (entry.value?.isPercent ?? false) || (awayValues[entry.type]?.isPercent ?? false)
            return StatLine(label: statLabels[entry.type] ?? entry.type, home: h, away: a, isPercent: percent)
        }
    }

    static func lineups(_ list: [LineupDTO], ratings: [Int: (rating: Double?, photo: URL?)]) -> [TeamLineup] {
        func convert(_ slot: LineupDTO.Slot) -> LineupPlayer? {
            guard let id = slot.player.id, let name = slot.player.name else { return nil }
            let extra = ratings[id]
            return LineupPlayer(id: id, name: name, number: slot.player.number, position: slot.player.pos,
                                grid: slot.player.grid, rating: extra?.rating, photoURL: extra?.photo)
        }
        return list.map { dto in
            TeamLineup(club: club(dto.team), formation: dto.formation,
                       starters: dto.startXI.compactMap(convert),
                       substitutes: dto.substitutes.compactMap(convert))
        }
    }

    static func ratings(_ list: [FixturePlayersDTO]) -> [Int: (rating: Double?, photo: URL?)] {
        var result: [Int: (rating: Double?, photo: URL?)] = [:]
        for team in list {
            for entry in team.players {
                let rating = entry.statistics.compactMap { $0.games?.rating?.value }.first
                result[entry.player.id] = (rating, entry.player.photo.flatMap(URL.init(string:)))
            }
        }
        return result
    }

    static func stats(_ dto: SeasonPlayerDTO) -> PlayerStats? {
        let stat = dto.statistics.first(where: { $0.league?.id == EvertonInfo.leagueID }) ?? dto.statistics.first
        guard let s = stat else { return nil }
        return PlayerStats(
            appearances: s.games?.appearences ?? 0, minutes: s.games?.minutes ?? 0, rating: s.games?.rating?.value,
            goals: s.goals?.total ?? 0, assists: s.goals?.assists ?? 0,
            shots: s.shots?.total ?? 0, shotsOnTarget: s.shots?.on ?? 0,
            passes: s.passes?.total ?? 0, keyPasses: s.passes?.key ?? 0,
            passAccuracy: Int(s.passes?.accuracy?.value ?? 0),
            tackles: s.tackles?.total ?? 0, dribbles: s.dribbles?.success ?? 0,
            yellow: s.cards?.yellow ?? 0, red: s.cards?.red ?? 0,
            saves: s.goals?.saves ?? 0, conceded: s.goals?.conceded ?? 0)
    }
}
