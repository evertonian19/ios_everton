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
}
