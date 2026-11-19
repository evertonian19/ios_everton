import XCTest
@testable import EvCore

final class MetricsTests: XCTestCase {
    func testRadarBoundedAndEmptyWithoutAppearances() {
        for player in Sample.players {
            let metrics = PlayerMetrics.radar(for: player, teamGames: 10)
            if (player.stats?.appearances ?? 0) == 0 {
                XCTAssertTrue(metrics.isEmpty, player.name)
            } else {
                XCTAssertGreaterThanOrEqual(metrics.count, 5, player.name)
                for metric in metrics { XCTAssertTrue((0...1).contains(metric.value), "\(player.name) \(metric.label)") }
            }
        }
    }

    func testRadarEmptyWithoutStats() {
        let player = Player(id: 1, name: "X", number: nil, position: .attacker, age: nil, photoURL: nil)
        XCTAssertTrue(PlayerMetrics.radar(for: player).isEmpty)
    }

    func testTopContributorsSortedAndNoGoalkeepers() {
        let top = PlayerMetrics.topContributors(Sample.players, limit: 5)
        XCTAssertFalse(top.isEmpty)
        let points = top.compactMap { $0.stats?.contribution }
        XCTAssertEqual(points, points.sorted(by: >))
        XCTAssertTrue(top.allSatisfy { $0.position != .goalkeeper })
    }

    func testStrengthsRules() {
        for player in Sample.players {
            let strengths = PlayerMetrics.strengths(for: player, teamGames: 10)
            XCTAssertLessThanOrEqual(strengths.count, 2)
            XCTAssertFalse(strengths.contains("규율"))
            if (player.stats?.appearances ?? 0) < PlayerMetrics.strengthMinAppearances {
                XCTAssertTrue(strengths.isEmpty, player.name)
            }
        }
    }

    func testSnapshotSquadIsCurrentSeason() {
        XCTAssertEqual(Sample.players.count, 24)
        let names = Set(Sample.players.map(\.name))
        XCTAssertTrue(names.contains("Jordan Pickford"))
        XCTAssertTrue(names.contains("Jack Grealish"))
        XCTAssertEqual(Sample.players.first { $0.name == "Jordan Pickford" }?.number, 1)
    }

    func testFlagsAndBodyFormatting() {
        XCTAssertEqual(Flags.emoji(for: "Brazil"), "🇧🇷")
        XCTAssertEqual(Flags.emoji(for: "Atlantis"), "")
        XCTAssertEqual(Fmt.height(185), "185 cm")
        XCTAssertEqual(Fmt.weight(nil), "-")
    }
}
