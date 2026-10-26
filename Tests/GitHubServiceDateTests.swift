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

    // 端末の暦を和暦・仏暦にしている場合を、その暦を渡して再現する
    private func deviceCalendar(_ identifier: Calendar.Identifier) -> Calendar {
        var deviceCalendar = Calendar(identifier: identifier)
        deviceCalendar.timeZone = calendar.timeZone
        return deviceCalendar
    }

    func testGetJournalPath_JapaneseCalendar_UsesGregorianYear() {
        let path = makeService().getJournalPath(now: date(2026, 3, 5, 12), calendar: deviceCalendar(.japanese))

        XCTAssertEqual(path, "log/2026/03/05.md", "端末が和暦でもパスの年は西暦にするべき")
    }

    func testGetJournalPath_BuddhistCalendar_UsesGregorianYear() {
        let path = makeService().getJournalPath(now: date(2026, 3, 5, 12), calendar: deviceCalendar(.buddhist))

        XCTAssertEqual(path, "log/2026/03/05.md", "端末が仏暦でもパスの年は西暦にするべき")
    }

    func testGetJournalPath_UsesTimeZoneOfGivenCalendar() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!

        // 東京の 2026-03-05 12:00 はニューヨークの 2026-03-04 22:00
        let path = makeService().getJournalPath(now: date(2026, 3, 5, 12), calendar: newYork)

        XCTAssertEqual(path, "log/2026/03/04.md")
    }

    // MARK: - createDefaultJournalContent Tests

    func testCreateDefaultJournalContent_ReturnsDateHeading() {
        let content = makeService().createDefaultJournalContent(now: date(2026, 3, 5, 12), calendar: calendar)

        XCTAssertEqual(content, "# 2026-03-05")
    }

    func testCreateDefaultJournalContent_BeforeTwoAM_UsesPreviousDay() {
        let content = makeService().createDefaultJournalContent(now: date(2027, 1, 1, 1), calendar: calendar)

        XCTAssertEqual(content, "# 2026-12-31", "見出しもパスと同じく午前2時までは前日にするべき")
    }

    func testCreateDefaultJournalContent_JapaneseCalendar_UsesGregorianYear() {
        let content = makeService().createDefaultJournalContent(now: date(2026, 3, 5, 12), calendar: deviceCalendar(.japanese))

        XCTAssertEqual(content, "# 2026-03-05", "端末が和暦でも見出しの年は西暦にするべき")
    }

    func testCreateDefaultJournalContent_BuddhistCalendar_UsesGregorianYear() {
        let content = makeService().createDefaultJournalContent(now: date(2026, 3, 5, 12), calendar: deviceCalendar(.buddhist))

        XCTAssertEqual(content, "# 2026-03-05", "端末が仏暦でも見出しの年は西暦にするべき")
    }
}
