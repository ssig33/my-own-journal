import XCTest
@testable import MyApp

final class AppSettingsModelTests: XCTestCase {

    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // テスト用のUserDefaultsを使用
        userDefaults = UserDefaults(suiteName: "TestDefaults")!
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        userDefaults = nil
        super.tearDown()
    }

    // MARK: - isConfigured Tests

    func testIsConfigured_AllFieldsFilled_ReturnsTrue() {
        let settings = AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )

        XCTAssertTrue(settings.isConfigured, "全てのフィールドが入力されている場合、isConfiguredはtrueを返すべき")
    }

    func testIsConfigured_EmptyGithubPAT_ReturnsFalse() {
        let settings = AppSettings(
            githubPAT: "",
            repositoryName: "test/repo",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )

        XCTAssertFalse(settings.isConfigured, "githubPATが空の場合、isConfiguredはfalseを返すべき")
    }

    func testIsConfigured_EmptyRepositoryName_ReturnsFalse() {
        let settings = AppSettings(
            githubPAT: "test_token",
            repositoryName: "",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )

        XCTAssertFalse(settings.isConfigured, "repositoryNameが空の場合、isConfiguredはfalseを返すべき")
    }

    func testIsConfigured_EmptyJournalRule_ReturnsFalse() {
        let settings = AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: "",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )

        XCTAssertFalse(settings.isConfigured, "journalRuleが空の場合、isConfiguredはfalseを返すべき")
    }

    // MARK: - defaultSettings Tests

    func testDefaultSettings_HasCorrectInitialValues() {
        let settings = AppSettings.defaultSettings

        XCTAssertEqual(settings.githubPAT, "", "デフォルトのgithubPATは空文字列であるべき")
        XCTAssertEqual(settings.repositoryName, "", "デフォルトのrepositoryNameは空文字列であるべき")
        XCTAssertEqual(settings.journalRule, "log/YYYY/MM/DD.md", "デフォルトのjournalRuleは'log/YYYY/MM/DD.md'であるべき")
        XCTAssertNil(settings.lastSpotlightIndexUpdate, "デフォルトのlastSpotlightIndexUpdateはnilであるべき")
        XCTAssertEqual(settings.indexedFilesCount, 0, "デフォルトのindexedFilesCountは0であるべき")
    }

    // MARK: - getLastSpotlightUpdateFormatted Tests

    func testGetLastSpotlightUpdateFormatted_NoUpdate_ReturnsUnupdated() {
        let settings = AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: nil,
            indexedFilesCount: 0
        )

        XCTAssertEqual(settings.getLastSpotlightUpdateFormatted(), "未更新", "lastSpotlightIndexUpdateがnilの場合、'未更新'を返すべき")
    }

    func testGetLastSpotlightUpdateFormatted_WithUpdate_ReturnsFormattedString() {
        let testDate = Date()
        let settings = AppSettings(
            githubPAT: "test_token",
            repositoryName: "test/repo",
            journalRule: "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: testDate,
            indexedFilesCount: 0
        )

        let result = settings.getLastSpotlightUpdateFormatted()
        XCTAssertFalse(result.isEmpty, "lastSpotlightIndexUpdateが設定されている場合、フォーマットされた文字列を返すべき")
        XCTAssertNotEqual(result, "未更新", "lastSpotlightIndexUpdateが設定されている場合、'未更新'以外を返すべき")
    }
}
