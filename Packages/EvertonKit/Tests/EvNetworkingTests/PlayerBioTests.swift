import XCTest
import EvCore
@testable import EvNetworking

final class PlayerBioTests: XCTestCase {
    private let now = PlayerBio.day("2026-11-19")!

    private func barryFromESPN() -> Player {
        Player(id: 301166, name: "Thierno Barry", number: 11, position: .attacker, age: 26, nationality: "Guinea",
               photoURL: nil, heightCM: 173, weightKG: 82, birthDate: PlayerBio.day("2000-01-12"),
               flagURL: URL(string: "https://a.espncdn.com/i/teamlogos/countries/500/gui.png"))
    }

    func testOverrideCorrectsBarry() {
        let fixed = PlayerBio.applyOverrides([barryFromESPN()])[0]
        XCTAssertEqual(fixed.nationality, "France")
        XCTAssertEqual(fixed.heightCM, 195)
        XCTAssertEqual(fixed.birthDate, PlayerBio.day("2002-10-21"))
        XCTAssertNil(fixed.weightKG)                       // 섞인 프로필의 몸무게는 버린다
        XCTAssertEqual(fixed.bioSource, "override")
        XCTAssertEqual(Set(fixed.bioDisputed.keys), ["nationality", "birthDate", "heightCM"])
        XCTAssertEqual(fixed.bioDisputed["nationality"], "Guinea")
        XCTAssertTrue(fixed.flagURL?.absoluteString.hasSuffix("/fra.png") == true)
    }

    func testAgeIsRecomputedFromBirthDate() {
        let found = BioFacts(birthDate: PlayerBio.day("2002-10-21"), heightCM: 195, nationality: "France", birthPlace: "Lyon", iso3: "FRA")
        let out = PlayerBio.apply(barryFromESPN(), found, source: "wikidata", now: now)
        XCTAssertEqual(out.age, 24)
        XCTAssertEqual(out.birthPlace, "Lyon")
    }

    func testUnitedKingdomDoesNotOverrideHomeNation() {
        var p = barryFromESPN()
        p.nationality = "England"
        let found = BioFacts(birthDate: p.birthDate, heightCM: 175, nationality: "United Kingdom", birthPlace: nil, iso3: "GBR")
        let out = PlayerBio.apply(p, found, source: "wikidata", now: now)
        XCTAssertEqual(out.nationality, "England")
        XCTAssertTrue(out.bioDisputed.isEmpty)
        XCTAssertEqual(out.weightKG, 82)
    }

    func testInsaneValuesAreRejected() {
        XCTAssertFalse(PlayerBio.sane(BioFacts(birthDate: nil, heightCM: 320, nationality: nil, birthPlace: nil, iso3: nil)))
        XCTAssertFalse(PlayerBio.sane(BioFacts(birthDate: PlayerBio.day("1950-01-01"), heightCM: 180, nationality: nil, birthPlace: nil, iso3: nil), now: now))
        XCTAssertTrue(PlayerBio.sane(BioFacts(birthDate: PlayerBio.day("2002-10-21"), heightCM: 195, nationality: nil, birthPlace: nil, iso3: nil), now: now))
    }

    func testNameNormalizationFoldsAccents() {
        XCTAssertEqual(PlayerBio.normalize("Merlin Röhl"), PlayerBio.normalize("Merlin Rohl"))
        XCTAssertEqual(PlayerBio.normalize("Jake O'Brien"), "jake obrien")
        XCTAssertEqual(PlayerBio.normalize("Maitland-Niles"), "maitland niles")
    }
}
