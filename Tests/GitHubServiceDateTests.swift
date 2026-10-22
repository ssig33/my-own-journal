import XCTest
@testable import MyApp

final class GitHubServiceDateTests: XCTestCase {

    var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    }

    private func makeService(journalRule: String = "log/YYYY/MM/DD.md") -> GitHubService {
        GitHubService(settings: AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: journalRule,
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        ))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - getCurrentDate Tests

    func testGetCurrentDate_BeforeTwoAM_ReturnsPreviousDay() {
        let result = makeService().getCurrentDate(now: date(2026, 10, 23, 1, 59), calendar: calendar)

        XCTAssertEqual(calendar.component(.day, from: result), 22, "午前2時より前は前日として扱うべき")
    }

    func testGetCurrentDate_AtTwoAM_ReturnsSameDay() {
        let result = makeService().getCurrentDate(now: date(2026, 10, 23, 2, 0), calendar: calendar)

        XCTAssertEqual(calendar.component(.day, from: result), 23, "午前2時以降は当日として扱うべき")
    }

    // MARK: - getJournalPath Tests

    func testGetJournalPath_ReplacesDatePlaceholdersWithZeroPadding() {
        let path = makeService().getJournalPath(now: date(2026, 3, 5, 12), calendar: calendar)

        XCTAssertEqual(path, "log/2026/03/05.md")
    }

    func testGetJournalPath_BeforeTwoAMOnNewYearsDay_UsesPreviousYear() {
        let path = makeService().getJournalPath(now: date(2027, 1, 1, 1), calendar: calendar)

        XCTAssertEqual(path, "log/2026/12/31.md", "年をまたぐ場合も前日の日付でパスを作るべき")
    }

    func testGetJournalPath_CustomRule() {
        let path = makeService(journalRule: "diary/YYYY-MM-DD.md").getJournalPath(now: date(2026, 10, 23, 9), calendar: calendar)

        XCTAssertEqual(path, "diary/2026-10-23.md")
    }
}
