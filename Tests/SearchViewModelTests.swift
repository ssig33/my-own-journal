import Combine
import XCTest
@testable import MyApp

final class SearchViewModelTests: XCTestCase {

    private let settings = AppSettings(
        githubPAT: "test_token",
        repositoryName: "owner/repo",
        journalRule: "log/YYYY/MM/DD.md",
        lastSpotlightIndexUpdate: nil,
        indexedFilesCount: 0
    )
    private let contents = "/repos/owner/repo/contents"

    override func setUp() {
        super.setUp()
        GitHubAPIStub.requests = []
        GitHubAPIStub.responder = { _, _ in (200, [[String: Any]]()) }
        URLProtocol.registerClass(GitHubAPIStub.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(GitHubAPIStub.self)
        GitHubAPIStub.responder = nil
        super.tearDown()
    }

    // 一覧の取得が終わるまで待つ
    private func waitForListing(_ viewModel: SearchViewModel) {
        let done = expectation(description: "listing")
        let subscription = viewModel.$isSearching.dropFirst().filter { !$0 }.sink { _ in done.fulfill() }
        wait(for: [done], timeout: 5)
        subscription.cancel()
    }

    // ルートの URL は末尾に / が付くので、比較の前に揃える
    private var requestedPaths: [String] {
        GitHubAPIStub.requests.map { $0.path.hasSuffix("/") ? String($0.path.dropLast()) : $0.path }
    }

    private func createNewFile(_ viewModel: SearchViewModel, name: String) -> (Bool, String?) {
        let done = expectation(description: "create")
        var result: (Bool, String?) = (false, nil)
        viewModel.newFileName = name
        viewModel.createNewFile { success, path in
            result = (success, path)
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        return result
    }

    // MARK: - navigateToParentDirectory

    func testNavigateToParent_FromNestedPath_ListsParent() {
        let viewModel = SearchViewModel(settings: settings)
        viewModel.currentPath = "log/2026/11"

        viewModel.navigateToParentDirectory()
        waitForListing(viewModel)

        XCTAssertEqual(viewModel.currentPath, "log/2026")
        XCTAssertEqual(requestedPaths, ["\(contents)/log/2026"])
    }

    func testNavigateToParent_FromTopLevelDirectory_ListsRoot() {
        let viewModel = SearchViewModel(settings: settings)
        viewModel.currentPath = "log"

        viewModel.navigateToParentDirectory()
        waitForListing(viewModel)

        XCTAssertEqual(viewModel.currentPath, "")
        XCTAssertEqual(requestedPaths, [contents])
    }

    func testNavigateToParent_AtRoot_DoesNothing() {
        let viewModel = SearchViewModel(settings: settings)

        viewModel.navigateToParentDirectory()

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.currentPath, "")
        XCTAssertTrue(GitHubAPIStub.requests.isEmpty)
    }

    // MARK: - openFileByPath

    func testOpenFileByPath_ListsParentAndEditsFile() {
        let viewModel = SearchViewModel(settings: settings)

        viewModel.openFileByPath("log/2026/11/20.md")
        waitForListing(viewModel)

        XCTAssertEqual(viewModel.currentPath, "log/2026/11")
        XCTAssertEqual(requestedPaths, ["\(contents)/log/2026/11"])
        XCTAssertEqual(viewModel.editingFile?.name, "20.md")
        XCTAssertEqual(viewModel.editingFile?.path, "log/2026/11/20.md")
    }

    func testOpenFileByPath_TopLevelFile_ListsRoot() {
        let viewModel = SearchViewModel(settings: settings)
        viewModel.currentPath = "log"

        viewModel.openFileByPath("README.md")
        waitForListing(viewModel)

        XCTAssertEqual(viewModel.currentPath, "")
        XCTAssertEqual(requestedPaths, [contents])
        XCTAssertEqual(viewModel.editingFile?.path, "README.md")
    }

    // MARK: - showNewFileForm

    func testShowNewFileForm_InDirectory_PrefillsDirectory() {
        let viewModel = SearchViewModel(settings: settings)
        viewModel.currentPath = "notes"

        viewModel.showNewFileForm()

        XCTAssertTrue(viewModel.showingNewFileForm)
        XCTAssertEqual(viewModel.newFileName, "notes/")
    }

    // MARK: - createNewFile

    // 存在しないファイルとして GET に 404 を返し、PUT を受け付ける
    private func acceptCreation() {
        GitHubAPIStub.responder = { method, _ in
            method == "GET" ? (404, [String: Any]()) : (201, ["content": ["sha": "new"]])
        }
    }

    private func createdContent() -> String? {
        guard let put = GitHubAPIStub.requests.first(where: { $0.method == "PUT" }),
              let base64 = put.body?["content"] as? String,
              let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func testCreateNewFile_WithoutExtension_AddsMarkdownExtension() {
        acceptCreation()
        let viewModel = SearchViewModel(settings: settings)
        viewModel.showingNewFileForm = true

        let (success, path) = createNewFile(viewModel, name: "notes/idea")

        XCTAssertTrue(success)
        XCTAssertEqual(path, "notes/idea.md")
        XCTAssertEqual(GitHubAPIStub.requests.last?.path, "\(contents)/notes/idea.md")
        XCTAssertEqual(createdContent(), "# idea")
        XCTAssertFalse(viewModel.showingNewFileForm)
        XCTAssertEqual(viewModel.newFileName, "")
    }

    func testCreateNewFile_EndingWithSlash_CreatesIndex() {
        acceptCreation()
        let viewModel = SearchViewModel(settings: settings)

        let (success, path) = createNewFile(viewModel, name: "notes/")

        XCTAssertTrue(success)
        XCTAssertEqual(path, "notes/index.md")
        XCTAssertEqual(createdContent(), "# index")
    }

    func testCreateNewFile_WithExtension_KeepsName() {
        acceptCreation()
        let viewModel = SearchViewModel(settings: settings)

        let (_, path) = createNewFile(viewModel, name: "notes/idea.md")

        XCTAssertEqual(path, "notes/idea.md")
    }

    func testCreateNewFile_EmptyName_FailsWithoutRequest() {
        let viewModel = SearchViewModel(settings: settings)

        let (success, path) = createNewFile(viewModel, name: "")

        XCTAssertFalse(success)
        XCTAssertNil(path)
        XCTAssertEqual(viewModel.errorMessage, "ファイル名を入力してください")
        XCTAssertTrue(GitHubAPIStub.requests.isEmpty)
    }

    func testCreateNewFile_ExistingFile_KeepsFormOpen() {
        GitHubAPIStub.responder = { _, _ in (200, ["sha": "old"]) }
        let viewModel = SearchViewModel(settings: settings)
        viewModel.showingNewFileForm = true

        let (success, _) = createNewFile(viewModel, name: "notes/idea")

        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.errorMessage, "notes/idea.md は既に存在します")
        XCTAssertTrue(viewModel.showingNewFileForm)
        XCTAssertEqual(viewModel.newFileName, "notes/idea")
        XCTAssertFalse(GitHubAPIStub.requests.contains { $0.method == "PUT" })
    }
}
