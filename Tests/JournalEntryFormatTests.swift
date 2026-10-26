import XCTest
@testable import MyApp

// formatJournalEntry の今の挙動を固定するテスト
final class JournalEntryFormatTests: XCTestCase {

    private let current = "# 2026-03-05"

    private func format(_ newEntry: String) -> String {
        GitHubService(settings: AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )).formatJournalEntry(currentContent: current, newEntry: newEntry)
    }

    func testSingleLine_AppendsAsListItem() {
        XCTAssertEqual(format("ごはんを食べた"), "# 2026-03-05\n- ごはんを食べた")
    }

    func testMultipleLines_AppendsAsBlockWithSeparator() {
        XCTAssertEqual(format("一行目\n二行目"), "# 2026-03-05\n-----\n一行目\n二行目")
    }

    func testMultipleLinesWithBlankLine_AppendsAsBlockWithSeparator() {
        XCTAssertEqual(format("一行目\n\n二行目"), "# 2026-03-05\n-----\n一行目\n\n二行目")
    }

    // 空行は行数に数えないので、末尾に改行があっても 1 行扱いになり、改行はそのまま残る
    func testSingleLineWithTrailingNewline_AppendsAsListItemKeepingNewline() {
        XCTAssertEqual(format("ごはんを食べた\n"), "# 2026-03-05\n- ごはんを食べた\n")
    }

    // 改行だけの入力は 0 行扱いで、区切りと改行だけが足される
    func testOnlyNewline_AppendsSeparatorAndNewline() {
        XCTAssertEqual(format("\n"), "# 2026-03-05\n-----\n\n")
    }

    // 空白だけの入力も 1 行として追記される
    func testOnlySpaces_AppendsAsListItem() {
        XCTAssertEqual(format("   "), "# 2026-03-05\n-    ")
    }
}
