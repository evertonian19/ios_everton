import XCTest
@testable import EvCore

final class ModelTests: XCTestCase {
    func testResultForHomeAndAway() {
        let finished = Sample.matches.filter { $0.phase == .finished }
        XCTAssertFalse(finished.isEmpty)
        for match in finished {
            let result = match.result()
            XCTAssertNotNil(result)
        }
        // 샘플 첫 경기: 홈에서 2:1 승리
        XCTAssertEqual(finished[0].result(), .win)
    }

    func testRecentResultsAreOldestFirstAndLimited() {
        let recent = Sample.matches.recentResults(3)
        XCTAssertEqual(recent.count, 3)
        XCTAssertTrue(recent[0].kickoff < recent[2].kickoff)
    }

    func testNextMatchIsUpcoming() {
        let next = Sample.matches.nextMatch()
        XCTAssertEqual(next?.phase, .upcoming)
    }

    func testPositionMapping() {
        XCTAssertEqual(Position(apiName: "Goalkeeper"), .goalkeeper)
        XCTAssertEqual(Position(apiName: "Defender"), .defender)
        XCTAssertEqual(Position(apiName: "Midfielder"), .midfielder)
        XCTAssertEqual(Position(apiName: "Attacker"), .attacker)
        XCTAssertEqual(Position(apiName: nil), .attacker)
    }

    func testFormatting() {
        XCTAssertEqual(Fmt.rating(7.26), "7.3")
        XCTAssertEqual(Fmt.rating(nil), "-")
        XCTAssertEqual(Fmt.stat(54, percent: true), "54%")
        XCTAssertEqual(Fmt.stat(4.5, percent: false), "4.5")
        let now = Date()
        XCTAssertNil(Fmt.countdown(to: now.addingTimeInterval(-5), from: now))
        XCTAssertEqual(Fmt.countdown(to: now.addingTimeInterval(3_661), from: now), "01:01:01")
        XCTAssertEqual(Fmt.countdown(to: now.addingTimeInterval(90_061), from: now), "1일 01:01:01")
    }

    func testDataReportChecks() {
        var report = DataReport(seasonFound: true, seasonStart: "2026-08-22", seasonEnd: "2027-05-23",
                                fixtureCount: 38, squadCount: 25, missingNumbers: 2)
        XCTAssertTrue(report.checks.contains { $0.title.contains("2026-27") && $0.level == .ok })
        XCTAssertTrue(report.checks.contains { $0.title == "등번호" && $0.level == .warning })
        report.seasonFound = false
        XCTAssertTrue(report.checks.contains { $0.title.contains("시즌") && $0.level == .problem })
    }
}
