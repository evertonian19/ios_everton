import XCTest
@testable import EvCore

final class TacticsTests: XCTestCase {
    private func sample(_ ids: [Int], _ formation: String?, match: Int, stats: [String: Double] = [:], gf: Int = 1, ga: Int = 0) -> TeamSample {
        let starters = ids.enumerated().map { LineupPlayer(id: $1, name: "P\($1)", number: $1, position: nil, grid: "\($0 + 1):1") }
        return TeamSample(matchID: match, opponent: "X\(match)", formation: formation, starters: starters, goalsFor: gf, goalsAgainst: ga, stats: stats)
    }

    func testPickXIMajorityFormationAndMostStartedMatch() throws {
        let core = Array(1...11)
        let samples = [sample(core, "4-4-2", match: 1), sample(Array(core.prefix(10)) + [20], "4-3-3", match: 2),
                       sample(core, "4-4-2", match: 3), sample(Array(core.prefix(9)) + [21, 22], "4-4-2", match: 4)]
        let picked = try XCTUnwrap(Tactics.pickXI(samples))
        XCTAssertEqual(picked.formation, "4-4-2")
        XCTAssertEqual(picked.counts.map(\.count), [3, 1])
        XCTAssertEqual(picked.xi.first { $0.id == 1 }?.starts, 4)
        XCTAssertEqual(Set(picked.xi.map(\.id)), Set(core))        // 선발 횟수 합이 가장 큰 경기의 11명
    }

    func testPickXIIgnoresIncompleteLineups() {
        XCTAssertNil(Tactics.pickXI([sample(Array(1...9), "4-4-2", match: 1)]))
        XCTAssertNil(Tactics.pickXI([sample(Array(1...11), nil, match: 1)]))
    }

    func testProfileAveragesAndTags() {
        let a = sample(Array(1...11), "4-4-2", match: 1, stats: ["점유율": 60, "슈팅": 16], gf: 2, ga: 0)
        let b = sample(Array(1...11), "4-4-2", match: 2, stats: ["점유율": 58, "슈팅": 16], gf: 3, ga: 1)
        let c = sample(Array(1...11), "4-4-2", match: 3, gf: 1, ga: 0)
        let p = Tactics.profile([a, b, c])
        XCTAssertEqual(p.possession, 59.0)
        XCTAssertNil(p.passPct)
        XCTAssertEqual(p.scored, 2.0)
        XCTAssertEqual(Set(p.tags), ["점유 지향", "슈팅 많음", "다득점", "단단한 수비"])
        XCTAssertNil(Tactics.profile([c]).possession)
    }

    func testMakeBuildsSummaryAndOpponents() {
        let t = Tactics.make([sample(Array(1...11), "4-2-3-1", match: 1, stats: ["점유율": 50, "슈팅": 10, "유효슈팅": 4])])
        XCTAssertEqual(t.formation, "4-2-3-1")
        XCTAssertEqual(t.xi.count, 11)
        XCTAssertEqual(t.opponents, ["X1"])
        XCTAssertTrue(t.summary.first?.contains("4-2-3-1") == true)
    }
}
