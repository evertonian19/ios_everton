import XCTest
@testable import EvNetworking

final class PLPhotosTests: XCTestCase {
    private let html = """
    <a href="/en/players/111234/jordan-pickford/overview">x</a><a href="/en/players/128295/christian-n-rgaard/overview">x</a>
    <a href="/en/players/513466/merlin-r-hl/overview">x</a><a href="/en/players/512462/jake-o-brien/overview">x</a>
    <a href="/en/players/224967/vitalii-mykolenko/overview">x</a><a href="/en/players/1/james-smith/overview">x</a>
    <a href="/en/players/2/john-smith/overview">x</a><a href="/en/players/111234/jordan-pickford/overview">dup</a>
    """

    func testParseDedupesInOrder() {
        XCTAssertEqual(PLSquadParser.parseSquad(html).map(\.id), ["111234", "128295", "513466", "512462", "224967", "1", "2"])
    }

    func testSpecialCharacterNamesMatch() {
        let entries = PLSquadParser.parseSquad(html)
        XCTAssertEqual(PLSquadParser.match("Christian Nørgaard", entries)?.id, "128295")
        XCTAssertEqual(PLSquadParser.match("Merlin Röhl", entries)?.id, "513466")
        XCTAssertEqual(PLSquadParser.match("Jake O'Brien", entries)?.id, "512462")
        XCTAssertEqual(PLSquadParser.match("Vitaliy Mykolenko", entries)?.id, "224967")
    }

    func testAmbiguousOrUnknownNotMatched() {
        let entries = PLSquadParser.parseSquad(html)
        XCTAssertNil(PLSquadParser.match("Sam Smith", entries))
        XCTAssertNil(PLSquadParser.match("Nobody Here", entries))
    }

    func testClubTitleParsingWithNewlines() {
        XCTAssertEqual(PLSquadParser.clubName("<title>\n  Manchester  United Squad Information & Player Stats | PL</title>"), "Manchester United")
        XCTAssertNil(PLSquadParser.clubName("<title>Not found</title>"))
    }

    func testEspnClubsMapToPLIDs() {
        let clubs: [Int: String] = [1: "Manchester United", 11: "Everton", 36: "Brighton and Hove Albion",
                                    39: "Wolverhampton Wanderers", 91: "AFC Bournemouth"]
        XCTAssertEqual(PLClubDirectory.clubID(for: ["Brighton & Hove Albion", "Brighton"], in: clubs), 36)
        XCTAssertEqual(PLClubDirectory.clubID(for: ["Wolverhampton Wanderers", "Wolves"], in: clubs), 39)
        XCTAssertEqual(PLClubDirectory.clubID(for: ["AFC Bournemouth", "Bournemouth"], in: clubs), 91)
    }

    func testUnknownOrAmbiguousClubIsNotMapped() {
        XCTAssertNil(PLClubDirectory.clubID(for: ["Hull City"], in: [11: "Everton"]))
        XCTAssertNil(PLClubDirectory.clubID(for: ["Everton"], in: [11: "Everton", 99: "Everton FC"]))
    }
}
