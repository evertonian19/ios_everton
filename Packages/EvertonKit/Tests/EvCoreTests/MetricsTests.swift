import XCTest
@testable import EvCore

final class MetricsTests: XCTestCase {
    func testRadarHasSixBoundedValues() {
        for player in Sample.players {
            let metrics = PlayerMetrics.radar(for: player)
            XCTAssertEqual(metrics.count, 6, player.name)
            for metric in metrics { XCTAssertTrue((0...1).contains(metric.value), "\(player.name) \(metric.label)") }
        }
    }

    func testRadarEmptyWithoutStats() {
        let player = Player(id: 1, name: "X", number: nil, position: .attacker, age: nil, photoURL: nil)
        XCTAssertTrue(PlayerMetrics.radar(for: player).isEmpty)
    }

    func testTopRatedSortedDescending() {
        let top = PlayerMetrics.topRated(Sample.players, limit: 3)
        XCTAssertEqual(top.count, 3)
        let ratings = top.compactMap { $0.stats?.rating }
        XCTAssertEqual(ratings, ratings.sorted(by: >))
    }

    func testStrengthsAreAtMostTwoAndKnownLabels() {
        let labels = Set(Sample.players.flatMap { PlayerMetrics.radar(for: $0).map(\.label) })
        for player in Sample.players {
            let strengths = PlayerMetrics.strengths(for: player)
            XCTAssertLessThanOrEqual(strengths.count, 2)
            for item in strengths { XCTAssertTrue(labels.contains(item)) }
        }
    }

    func testFlagsAndBodyFormatting() {
        XCTAssertEqual(Flags.emoji(for: "Brazil"), "🇧🇷")
        XCTAssertEqual(Flags.emoji(for: "Ivory Coast"), "🇨🇮")
        XCTAssertEqual(Flags.emoji(for: "Atlantis"), "")
        XCTAssertEqual(Fmt.height(185), "185 cm")
        XCTAssertEqual(Fmt.weight(nil), "-")
        XCTAssertEqual(Fmt.capacity(52888), "52,888명")
    }
}
