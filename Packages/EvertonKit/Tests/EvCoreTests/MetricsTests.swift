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
}
