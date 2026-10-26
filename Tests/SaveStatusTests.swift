import XCTest
@testable import MyApp

final class SaveStatusTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private func date(hour: Int, minute: Int, second: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        return calendar.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: hour, minute: minute, second: second))!
    }

    func testSuccess_ShowsSavedTimeIn24HourFormat() {
        let message = SaveStatus.message(success: true, error: nil, at: date(hour: 21, minute: 4, second: 9), timeZone: tokyo)

        XCTAssertEqual(message, "保存完了: 21:04:09")
    }

    func testSuccess_IgnoresLeftoverError() {
        let message = SaveStatus.message(success: true, error: "前回のエラー", at: date(hour: 9, minute: 0, second: 0), timeZone: tokyo)

        XCTAssertEqual(message, "保存完了: 09:00:00")
    }

    func testFailure_WithError_ShowsError() {
        XCTAssertEqual(SaveStatus.message(success: false, error: "認証エラー"), "保存失敗: 認証エラー")
    }

    func testFailure_WithoutError_ShowsFailureOnly() {
        XCTAssertEqual(SaveStatus.message(success: false, error: nil), "保存失敗")
    }
}
