import XCTest

// myownjournal://open?path=... でアプリを開き、そのファイルの編集画面が出ることを確かめる。
// 環境変数 E2E_GITHUB_TOKEN があれば公開リポジトリ gonzalezreal/swift-markdown-ui を実際に読み、
// 編集画面にファイルの中身が出ることまで確かめる (xcodebuild には TEST_RUNNER_E2E_GITHUB_TOKEN で渡す)。
// 書き込み権限の無いリポジトリなので、自動保存が走っても何も書き換わらない。
final class DeepLinkUITests: XCTestCase {
    private let repository = "gonzalezreal/swift-markdown-ui"
    private var token: String? { ProcessInfo.processInfo.environment["E2E_GITHUB_TOKEN"].flatMap { $0.isEmpty ? nil : $0 } }

    override func setUp() {
        continueAfterFailure = false
    }

    func testDeepLinkOpensFileOnColdAndWarmStart() throws {
        let app = XCUIApplication()

        // 設定を launch argument で渡し、設定画面の保存ボタンで永続化する
        app.launchArguments = [
            "-githubPAT", token ?? "dummy-token",
            "-repositoryName", repository,
            "-journalRule", "log/YYYY/MM/DD.md",
        ]
        app.launch()
        app.buttons["設定"].firstMatch.tap()
        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10))
        saveButton.tap()
        app.terminate()

        // アプリが動いていない状態から開く
        try openDeepLink(app, path: "README.md")
        try assertEditorOpened(app, containing: "maintenance mode")

        // アプリが動いている状態で別のファイルを開く
        try openDeepLink(app, path: "Sources/MarkdownUI/Documentation.docc/MarkdownUI.md")
        try assertEditorOpened(app, containing: "# ``MarkdownUI``")
    }

    private func openDeepLink(_ app: XCUIApplication, path: String) throws {
        var components = URLComponents()
        components.scheme = "myownjournal"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: path)]
        app.open(try XCTUnwrap(components.url))

        // 「"My Own Journal" で開きますか?」の確認が出たら開く
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let openButton = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["開く", "Open"])).firstMatch
        if openButton.waitForExistence(timeout: 5) {
            openButton.tap()
        }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    private func assertEditorOpened(_ app: XCUIApplication, containing text: String) throws {
        XCTAssertTrue(app.navigationBars["ファイル編集"].waitForExistence(timeout: 10), "ディープリンクで編集画面が開くべき")

        guard token != nil else { return }
        let editor = app.textViews.firstMatch
        let loaded = NSPredicate { _, _ in
            (editor.value as? String)?.contains(text) == true
        }
        expectation(for: loaded, evaluatedWith: nil)
        waitForExpectations(timeout: 15)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = text
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
