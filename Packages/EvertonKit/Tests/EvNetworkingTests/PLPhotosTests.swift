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
        XCTAssertEqual(PLPhotos.parseSquad(html).map(\.id), ["111234", "128295", "513466", "512462", "224967", "1", "2"])
    }

    func testSpecialCharacterNamesMatch() {
        let entries = PLPhotos.parseSquad(html)
        XCTAssertEqual(PLPhotos.match("Christian Nørgaard", entries)?.id, "128295")
        XCTAssertEqual(PLPhotos.match("Merlin Röhl", entries)?.id, "513466")
        XCTAssertEqual(PLPhotos.match("Jake O'Brien", entries)?.id, "512462")
        XCTAssertEqual(PLPhotos.match("Vitaliy Mykolenko", entries)?.id, "224967")
    }

    func testAmbiguousOrUnknownNotMatched() {
        let entries = PLPhotos.parseSquad(html)
        XCTAssertNil(PLPhotos.match("Sam Smith", entries))
        XCTAssertNil(PLPhotos.match("Nobody Here", entries))
    }
}
