import XCTest
import EvCore
@testable import EvNetworking

final class ESPNDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    func testScheduleMapsMatchesAndPhases() throws {
        let json = """
        {"season":{"year":2026,"displayName":"2026-27 English Premier League"},"events":[
         {"id":"401879242","date":"2026-11-06T20:00Z","competitions":[{"venue":{"fullName":"Hill Dickinson Stadium"},
           "status":{"type":{"state":"post","description":"Full Time"}},
           "competitors":[
             {"homeAway":"home","score":{"displayValue":"3"},"team":{"id":"368","displayName":"Everton","shortDisplayName":"Everton","abbreviation":"EVE","logos":[{"href":"https://x/368.png"}]}},
             {"homeAway":"away","score":{"displayValue":"1"},"team":{"id":"388","displayName":"Coventry City","shortDisplayName":"Coventry","abbreviation":"COV"}}]}]},
         {"id":"401879237","date":"2026-11-23T20:00Z","competitions":[{"status":{"type":{"state":"pre","description":"Scheduled"}},
           "competitors":[
             {"homeAway":"home","score":"0","team":{"id":"337","displayName":"Brentford"}},
             {"homeAway":"away","score":"0","team":{"id":"368","displayName":"Everton"}}]}]}]}
        """
        let schedule = try decode(ESPNSchedule.self, json)
        let matches = ESPNMapping.schedule([schedule])
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].phase, .finished)
        XCTAssertEqual(matches[0].result(), .win)
        XCTAssertEqual(matches[0].venue, "Hill Dickinson Stadium")
        XCTAssertEqual(matches[1].phase, .upcoming)
        XCTAssertNil(matches[1].homeGoals)
        XCTAssertFalse(matches[1].isHome())
        XCTAssertEqual(matches[1].opponent().name, "Brentford")
    }

    func testRosterConvertsUnitsAndStats() throws {
        let json = """
        {"season":{"displayName":"2026-27 English Premier League"},"coach":[{"firstName":"David","lastName":"Moyes"}],
         "athletes":[{"id":"159443","displayName":"Jordan Pickford","shortName":"J. Pickford","jersey":"1","age":32,
           "height":73.0,"weight":170.0,"dateOfBirth":"1994-03-07T08:00Z","citizenship":"England",
           "flag":{"href":"https://x/eng.png"},"position":{"abbreviation":"G"},"birthPlace":{},
           "statistics":{"splits":{"categories":[{"stats":[{"name":"appearances","value":10},{"name":"saves","value":28},{"name":"goalsConceded","value":10}]}]}}},
          {"id":"1","displayName":"Youth Player","position":{"abbreviation":"M"}}]}
        """
        let players = ESPNMapping.roster(try decode(ESPNRoster.self, json))
        XCTAssertEqual(players.count, 2)
        let pickford = try XCTUnwrap(players.first { $0.name == "Jordan Pickford" })
        XCTAssertEqual(pickford.number, 1)
        XCTAssertEqual(pickford.position, .goalkeeper)
        XCTAssertEqual(pickford.heightCM, 185)
        XCTAssertEqual(pickford.weightKG, 77)
        XCTAssertNotNil(pickford.birthDate)
        XCTAssertEqual(pickford.stats?.appearances, 10)
        XCTAssertEqual(pickford.stats?.saves, 28)
        XCTAssertNil(pickford.photoURL)
        XCTAssertNil(players.first { $0.name == "Youth Player" }?.stats)
    }

    func testStandingsZonesAndOrder() throws {
        let json = """
        {"children":[{"standings":{"entries":[
          {"team":{"id":"368","displayName":"Everton"},"stats":[{"name":"rank","value":6},{"name":"points","value":16},{"name":"pointsFor","value":12},{"name":"pointsAgainst","value":10}]},
          {"team":{"id":"359","displayName":"Arsenal"},"note":{"description":"Champions League"},"stats":[{"name":"rank","value":1},{"name":"points","value":25}]}]}}]}
        """
        let rows = ESPNMapping.standings(try decode(ESPNStandings.self, json))
        XCTAssertEqual(rows.map(\.rank), [1, 6])
        XCTAssertEqual(rows[0].zone, .champions)
        XCTAssertEqual(rows[1].goalDifference, 2)
    }

    func testLineupLayoutUsesFormationRows() {
        let starters: [(place: Int, position: String?)] = [
            (1, "G"), (6, "CD-L"), (5, "CD-R"), (3, "LB"), (2, "RB"),
            (4, "LM"), (8, "RM"), (11, "AM-L"), (10, "AM"), (7, "AM-R"), (9, "F"),
        ]
        let grid = ESPNMapping.layout(formation: "4-2-3-1", starters: starters)
        XCTAssertEqual(grid[1], "1:1")
        XCTAssertEqual(Set(grid.values).count, 11)
        XCTAssertEqual(grid[3], "2:1")      // 왼쪽 풀백이 수비 줄 맨 왼쪽
        XCTAssertEqual(grid[9], "5:1")      // 원톱은 맨 앞 줄
        XCTAssertEqual(grid[10], "4:2")     // 가운데 공격형 미드필더
    }

    func testEventsAndTeamStats() throws {
        let json = """
        {"boxscore":{"teams":[
           {"team":{"id":"368"},"statistics":[{"name":"possessionPct","displayValue":"49.8"},{"name":"totalShots","displayValue":"16"},{"name":"passPct","displayValue":"0.8"}]},
           {"team":{"id":"388"},"statistics":[{"name":"possessionPct","displayValue":"50.2"},{"name":"totalShots","displayValue":"15"},{"name":"passPct","displayValue":"0.8"}]}]},
         "keyEvents":[
           {"id":"2","type":{"type":"goal---header","text":"Goal - Header"},"clock":{"displayValue":"56'"},"team":{"id":"368"},
            "participants":[{"athlete":{"displayName":"Thierno Barry"}},{"athlete":{"displayName":"Vitaliy Mykolenko"}}]},
           {"id":"1","type":{"type":"yellow-card","text":"Yellow Card"},"clock":{"displayValue":"45'+2'"},"team":{"id":"388"},"participants":[{"athlete":{"displayName":"X"}}]},
           {"id":"3","type":{"type":"substitution","text":"Substitution"},"clock":{"displayValue":"73'"},"team":{"id":"368"}}]}
        """
        let summary = try decode(ESPNSummary.self, json)
        let lines = ESPNMapping.statLines(summary, homeID: 368, awayID: 388)
        XCTAssertEqual(lines.map(\.label), ["점유율", "슈팅", "패스 성공률"])
        XCTAssertEqual(lines[2].home, 80)
        let events = ESPNMapping.events(summary)
        XCTAssertEqual(events.map(\.kind), [.yellow, .goal])
        XCTAssertEqual(events[0].minuteText, "45+2'")
        XCTAssertEqual(events[1].assist, "Vitaliy Mykolenko")
    }
}
