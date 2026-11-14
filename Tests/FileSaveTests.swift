import XCTest
@testable import MyApp

// api.github.com へのリクエストを記録し、テストが決めた応答を返す
final class GitHubAPIStub: URLProtocol {
    struct Recorded {
        let method: String
        let path: String
        let body: [String: Any]?
    }

    static var responder: ((String, String) -> (Int, Any))?
    static var requests: [Recorded] = []

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "api.github.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        GitHubAPIStub.requests.append(Recorded(method: method, path: path, body: GitHubAPIStub.jsonBody(of: request)))

        let (status, json) = GitHubAPIStub.responder?(method, path) ?? (404, [String: Any]())
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    // URLProtocol に届くリクエストの body は httpBodyStream に入っている
    private static func jsonBody(of request: URLRequest) -> [String: Any]? {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            var buffer = Data()
            stream.open()
            let chunk = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(chunk, maxLength: 1024)
                if count <= 0 { break }
                buffer.append(chunk, count: count)
            }
            chunk.deallocate()
            stream.close()
            data = buffer
        }
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

final class FileSaveTests: XCTestCase {

    private let settings = AppSettings(
        githubPAT: "test_token",
        repositoryName: "owner/repo",
        journalRule: "log/YYYY/MM/DD.md",
        lastSpotlightIndexUpdate: nil,
        indexedFilesCount: 0
    )
    private let filePath = "/repos/owner/repo/contents/notes/a.md"

    override func setUp() {
        super.setUp()
        GitHubAPIStub.requests = []
        GitHubAPIStub.responder = nil
        URLProtocol.registerClass(GitHubAPIStub.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(GitHubAPIStub.self)
        GitHubAPIStub.responder = nil
        super.tearDown()
    }

    private func fileJSON(_ content: String, sha: String) -> [String: Any] {
        ["content": Data(content.utf8).base64EncodedString(), "sha": sha]
    }

    // PUT の応答。content.sha に保存後の SHA が入る
    private func putJSON(sha: String) -> [String: Any] {
        ["content": ["sha": sha], "commit": ["sha": "commit-\(sha)"]]
    }

    private func save(_ viewModel: EditViewModel, content: String, path: String = "notes/a.md") -> Bool {
        let done = expectation(description: "save")
        var result = false
        viewModel.journalContent = content
        viewModel.saveFile(path: path) { success in
            result = success
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        return result
    }

    private var puts: [GitHubAPIStub.Recorded] {
        GitHubAPIStub.requests.filter { $0.method == "PUT" }
    }

    // MARK: - savedFileSHA

    func testSavedFileSHA_ReadsContentSHA() throws {
        let data = try JSONSerialization.data(withJSONObject: putJSON(sha: "abc"))

        XCTAssertEqual(GitHubService.savedFileSHA(from: data), "abc")
    }

    func testSavedFileSHA_WithoutContent_ReturnsNil() throws {
        let data = try JSONSerialization.data(withJSONObject: ["message": "ok"])

        XCTAssertNil(GitHubService.savedFileSHA(from: data))
        XCTAssertNil(GitHubService.savedFileSHA(from: nil))
    }

    // MARK: - EditViewModel.saveFile

    func testSaveFile_AfterRefresh_UsesSHAFromPreviousSave() {
        var putCount = 0
        GitHubAPIStub.responder = { method, path in
            XCTAssertEqual(path, self.filePath)
            if method == "GET" {
                return (200, self.fileJSON("# a", sha: "sha-0"))
            }
            putCount += 1
            return (200, self.putJSON(sha: "sha-\(putCount)"))
        }

        let viewModel = EditViewModel(settings: settings, initialContent: "")
        let loaded = expectation(description: "refresh")
        viewModel.refreshFileContent(path: "notes/a.md") { success in
            XCTAssertTrue(success)
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 5)
        XCTAssertEqual(viewModel.journalContent, "# a")
        XCTAssertFalse(viewModel.hasChanges)

        XCTAssertTrue(save(viewModel, content: "# a\n1"))
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertTrue(save(viewModel, content: "# a\n2"))
        XCTAssertTrue(save(viewModel, content: "# a\n3"))

        XCTAssertEqual(puts.map { $0.body?["sha"] as? String }, ["sha-0", "sha-1", "sha-2"])
        // 読み込み後に GET しているのは refreshFileContent の 1 回だけ
        XCTAssertEqual(GitHubAPIStub.requests.filter { $0.method == "GET" }.count, 1)
    }

    func testSaveFile_WithoutRefresh_FetchesLatestSHAEveryTime() {
        var getCount = 0
        GitHubAPIStub.responder = { method, _ in
            if method == "GET" {
                getCount += 1
                return (200, self.fileJSON("# a", sha: "remote-\(getCount)"))
            }
            return (200, self.putJSON(sha: "saved"))
        }

        let viewModel = EditViewModel(settings: settings, initialContent: "")

        XCTAssertTrue(save(viewModel, content: "# a\n1"))
        XCTAssertTrue(save(viewModel, content: "# a\n2"))

        XCTAssertEqual(puts.map { $0.body?["sha"] as? String }, ["remote-1", "remote-2"])
    }

    func testSaveFile_EmptyContent_CallsCompletionWithoutPut() {
        GitHubAPIStub.responder = { _, _ in (200, self.putJSON(sha: "saved")) }

        let viewModel = EditViewModel(settings: settings, initialContent: "# a")

        XCTAssertFalse(save(viewModel, content: ""))
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertEqual(viewModel.error, "空の内容は保存しません")
        XCTAssertTrue(GitHubAPIStub.requests.isEmpty)
    }

    func testResetContent_LoadedContentHasNoChanges() {
        let viewModel = EditViewModel(settings: settings, initialContent: "")

        viewModel.resetContent("# 読み込んだ内容")
        XCTAssertFalse(viewModel.hasChanges)

        viewModel.journalContent = "# 読み込んだ内容\n- 追記"
        XCTAssertTrue(viewModel.hasChanges)
    }

    func testRefreshFileContent_Error_CallsCompletionWithFalse() {
        GitHubAPIStub.responder = { _, _ in (401, [String: Any]()) }

        let viewModel = EditViewModel(settings: settings, initialContent: "")
        let loaded = expectation(description: "refresh")
        viewModel.refreshFileContent(path: "notes/a.md") { success in
            XCTAssertFalse(success)
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 5)

        XCTAssertEqual(viewModel.error, "認証エラー: GitHub PATが無効です")
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - GitHubService.createFile

    func testCreateFile_ExistingFile_FailsWithoutPut() {
        GitHubAPIStub.responder = { _, _ in (200, self.fileJSON("# 既存", sha: "sha-0")) }

        let done = expectation(description: "create")
        GitHubService(settings: settings).createFile(path: "notes/a.md", content: "# a") { success, error, _, _ in
            XCTAssertFalse(success)
            XCTAssertEqual(error, "notes/a.md は既に存在します")
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        XCTAssertTrue(puts.isEmpty)
    }

    func testCreateFile_NewFile_PutsWithoutSHA() {
        GitHubAPIStub.responder = { method, _ in
            method == "GET" ? (404, ["message": "Not Found"]) : (201, self.putJSON(sha: "new"))
        }

        let done = expectation(description: "create")
        GitHubService(settings: settings).createFile(path: "notes/a.md", content: "# a") { success, error, _, sha in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            XCTAssertEqual(sha, "new")
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        XCTAssertEqual(puts.count, 1)
        XCTAssertNil(puts.first?.body?["sha"])
        XCTAssertEqual(puts.first?.body?["content"] as? String, Data("# a".utf8).base64EncodedString())
    }
}
