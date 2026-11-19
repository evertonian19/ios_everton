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

    func testCandidatesAreHighResThenLowResAndSkipManual() {
        let entries = PLSquadParser.parseSquad(html)
        let players = [Player(id: 1, name: "Jordan Pickford", number: nil, position: .goalkeeper, age: nil, photoURL: nil),
                       Player(id: 2, name: "Merlin Röhl", number: nil, position: .midfielder, age: nil, photoURL: nil)]
        let out = PLPhotos.candidates(players, entries: entries, keep: [2])
        XCTAssertEqual(Array(out.keys), [1])
        XCTAssertEqual(out[1]?.map(\.url.lastPathComponent), ["p111234.png", "111234.png"])
        XCTAssertEqual(out[1]?.first?.source, .premierleague)
    }

    func testPhotoSniffRejectsSmallAndNonImages() {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) + Data(repeating: 0x78, count: 9_000)
        XCTAssertEqual(PhotoCache.sniff(png), "png")
        XCTAssertEqual(PhotoCache.sniff(Data([0xFF, 0xD8, 0xFF]) + Data(repeating: 0x78, count: 9_000)), "jpg")
        XCTAssertNil(PhotoCache.sniff(Data("<html>429</html>".utf8) + Data(repeating: 0x20, count: 9_000)))
        XCTAssertNil(PhotoCache.sniff(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) + Data(repeating: 0x78, count: 100)))
    }

    func testSourceRankOrdersManualFirst() {
        XCTAssertTrue(PhotoCandidate.Source.manual < .premierleague)
        XCTAssertTrue(PhotoCandidate.Source.premierleague < .commons)
    }
}
