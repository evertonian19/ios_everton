import XCTest
import EvCore
@testable import EvNetworking

final class DecodingTests: XCTestCase {
    func testFixtureEnvelopeMapsToMatch() throws {
        let json = """
        {"errors":[],"results":1,"paging":{"current":1,"total":1},"response":[{
          "fixture":{"id":7,"date":"2026-08-22T14:00:00+00:00","status":{"short":"FT","long":"Match Finished","elapsed":90},"venue":{"name":"Hill Dickinson Stadium"}},
          "league":{"name":"Premier League","round":"Regular Season - 2"},
          "teams":{"home":{"id":45,"name":"Everton","logo":"https://x/45.png"},"away":{"id":40,"name":"Liverpool","logo":null}},
          "goals":{"home":2,"away":1}}]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[FixtureDTO]>.self, from: json)
        XCTAssertNil(envelope.errorMessage)
        let match = try XCTUnwrap(envelope.response.compactMap(Mapping.match).first)
        XCTAssertEqual(match.phase, .finished)
        XCTAssertEqual(match.result(), .win)
        XCTAssertEqual(match.opponent().name, "Liverpool")
    }

    func testErrorsObjectIsReported() throws {
        let json = #"{"errors":{"token":"Error/Missing application key"},"response":[]}"#.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[FixtureDTO]>.self, from: json)
        XCTAssertEqual(envelope.errorMessage, "Error/Missing application key")
    }

    func testStatisticsMixedValueTypes() throws {
        let json = """
        {"response":[
          {"team":{"id":45,"name":"Everton"},"statistics":[{"type":"Ball Possession","value":"58%"},{"type":"Total Shots","value":12},{"type":"Fouls","value":null}]},
          {"team":{"id":40,"name":"Liverpool"},"statistics":[{"type":"Ball Possession","value":"42%"},{"type":"Total Shots","value":7},{"type":"Fouls","value":9}]}
        ]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[StatisticsDTO]>.self, from: json)
        let lines = Mapping.statLines(envelope.response, homeID: 45)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].label, "점유율")
        XCTAssertTrue(lines[0].isPercent)
        XCTAssertEqual(lines[0].home, 58)
        XCTAssertEqual(lines[1].away, 7)
        XCTAssertEqual(lines[2].home, 0)
    }

    func testPlayerRatingStringIsParsed() throws {
        let json = """
        {"response":[{"team":{"id":45,"name":"Everton"},"players":[
          {"player":{"id":1,"name":"J. Pickford","photo":"https://x/1.png"},"statistics":[{"games":{"rating":"7.3"}}]}]}]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[FixturePlayersDTO]>.self, from: json)
        let ratings = Mapping.ratings(envelope.response)
        XCTAssertEqual(ratings[1]?.rating, 7.3)
    }

    func testRSSParsing() {
        let xml = """
        <?xml version="1.0"?><rss xmlns:media="http://search.yahoo.com/mrss/"><channel>
        <item><title><![CDATA[Blues win at home]]></title><description><![CDATA[<p>Great &amp; late goal</p>]]></description>
        <link>https://example.com/a</link><guid>a1</guid><pubDate>Sat, 22 Aug 2026 18:00:00 +0000</pubDate>
        <media:thumbnail url="https://example.com/a.jpg"/></item></channel></rss>
        """.data(using: .utf8)!
        let items = RSSParser.parse(xml)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Blues win at home")
        XCTAssertEqual(items[0].summary, "Great & late goal")
        XCTAssertNotNil(items[0].date)
        XCTAssertEqual(items[0].imageURL?.absoluteString, "https://example.com/a.jpg")
    }

    func testEventsMapping() throws {
        let json = """
        {"response":[
          {"time":{"elapsed":12,"extra":null},"team":{"id":45,"name":"Everton"},"player":{"id":1,"name":"A"},"assist":{"id":2,"name":"B"},"type":"Goal","detail":"Normal Goal"},
          {"time":{"elapsed":45,"extra":2},"team":{"id":40,"name":"Liverpool"},"player":{"id":3,"name":"C"},"assist":{"id":null,"name":null},"type":"Card","detail":"Yellow Card"},
          {"time":{"elapsed":60,"extra":null},"team":{"id":45,"name":"Everton"},"player":{"id":4,"name":"D"},"assist":{"id":5,"name":"E"},"type":"subst","detail":"Substitution 1"}
        ]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[EventDTO]>.self, from: json)
        let events = Mapping.events(envelope.response)
        XCTAssertEqual(events.map(\.kind), [.goal, .yellow, .substitution])
        XCTAssertEqual(events[1].minuteText, "45+2'")
        XCTAssertEqual(events.filter { $0.isKey }.count, 2)
    }

    func testStandingsMappingAndZones() throws {
        let json = """
        {"response":[{"league":{"standings":[[
          {"rank":2,"team":{"id":45,"name":"Everton","logo":null},"points":20,"form":"WWDLW","description":"Relegation - Championship",
           "all":{"played":10,"win":6,"draw":2,"lose":2,"goals":{"for":15,"against":9}}},
          {"rank":1,"team":{"id":42,"name":"Arsenal","logo":null},"points":25,"form":"WWWWW","description":"Promotion - Champions League (League phase)",
           "all":{"played":10,"win":8,"draw":1,"lose":1,"goals":{"for":22,"against":6}}}
        ]]}}]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[StandingsDTO]>.self, from: json)
        let rows = Mapping.standings(envelope.response)
        XCTAssertEqual(rows.map(\.rank), [1, 2])
        XCTAssertEqual(rows[0].zone, .champions)
        XCTAssertEqual(rows[1].zone, .relegation)
        XCTAssertEqual(rows[0].goalDifference, 16)
    }

    func testLeagueSeasonLookup() throws {
        let json = #"{"response":[{"seasons":[{"year":2025,"start":"2025-08-15","end":"2026-05-24","current":false},{"year":2026,"start":"2026-08-22","end":"2027-05-23","current":true}]}]}"#.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[LeagueInfoDTO]>.self, from: json)
        XCTAssertEqual(envelope.response.first?.seasons.first(where: { $0.year == EvertonInfo.season })?.start, "2026-08-22")
    }

    func testClubsMapping() throws {
        let json = """
        {"response":[{"team":{"id":45,"name":"Everton","code":"EVE","country":"England","founded":1878,"logo":"https://x/45.png"},
          "venue":{"name":"Hill Dickinson Stadium","city":"Liverpool","capacity":52888,"image":"https://x/v.png"}}]}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(Envelope<[TeamEntryDTO]>.self, from: json)
        let info = try XCTUnwrap(envelope.response.map(Mapping.clubInfo).first)
        XCTAssertEqual(info.founded, 1878)
        XCTAssertEqual(info.capacity, 52888)
        XCTAssertEqual(info.venueName, "Hill Dickinson Stadium")
    }

    func testBodyAndBirthParsing() {
        XCTAssertEqual(Mapping.number("185 cm"), 185)
        XCTAssertEqual(Mapping.number("79 kg"), 79)
        XCTAssertNil(Mapping.number(nil))
        XCTAssertNil(Mapping.number("N/A"))
        XCTAssertNotNil(Mapping.birthDate("1994-03-07"))
        XCTAssertNil(Mapping.birthDate("garbage"))
    }
}
