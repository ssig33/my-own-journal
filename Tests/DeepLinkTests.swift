import XCTest
import CoreSpotlight
@testable import MyApp

final class DeepLinkTests: XCTestCase {

    // Spotlight の検索結果をタップしたときにアプリへ渡される NSUserActivity を作る
    private func userActivity(for item: CSSearchableItem) -> NSUserActivity {
        let activity = NSUserActivity(activityType: CSSearchableItemActionType)
        activity.userInfo = [CSSearchableItemActivityIdentifier: item.uniqueIdentifier]
        return activity
    }

    // MARK: - Spotlight

    func testSpotlightItem_RoundTripsToFilePath() {
        let item = SpotlightIndexItem(name: "05.md", path: "log/2026/03/05.md", content: "# 2026-03-05").toSearchableItem()

        XCTAssertEqual(DeepLink.path(from: userActivity(for: item)), "log/2026/03/05.md")
    }

    func testSpotlightItem_RoundTripsNonASCIIPath() {
        let item = SpotlightIndexItem(name: "メモ.md", path: "notes/日本語 メモ.md", content: "本文").toSearchableItem()

        XCTAssertEqual(DeepLink.path(from: userActivity(for: item)), "notes/日本語 メモ.md")
    }

    func testSpotlightItem_SamePathHasStableIdentifier() {
        let first = SpotlightIndexItem(name: "a.md", path: "a.md", content: "1").toSearchableItem()
        let second = SpotlightIndexItem(name: "a.md", path: "a.md", content: "2").toSearchableItem()

        XCTAssertEqual(first.uniqueIdentifier, second.uniqueIdentifier, "同じファイルは再インデックスしても同じ ID になるべき")
    }

    func testUserActivity_OtherActivityType_ReturnsNil() {
        let activity = NSUserActivity(activityType: "com.example.other")
        activity.userInfo = [CSSearchableItemActivityIdentifier: "a.md"]

        XCTAssertNil(DeepLink.path(from: activity))
    }

    // MARK: - URL

    func testURL_ParsesPathQuery() {
        let url = URL(string: "myownjournal://open?path=log/2026/03/05.md")!

        XCTAssertEqual(DeepLink.path(from: url), "log/2026/03/05.md")
    }

    func testURL_ParsesPercentEncodedPath() {
        let url = URL(string: "myownjournal://open?path=notes/%E6%97%A5%E6%9C%AC%E8%AA%9E%20%E3%83%A1%E3%83%A2.md")!

        XCTAssertEqual(DeepLink.path(from: url), "notes/日本語 メモ.md")
    }

    func testURL_StripsLeadingSlash() {
        let url = URL(string: "myownjournal://open?path=/README.md")!

        XCTAssertEqual(DeepLink.path(from: url), "README.md")
    }

    func testURL_RoundTripsBuiltURL() {
        let url = DeepLink.url(forPath: "notes/日本語 メモ&その他.md")!

        XCTAssertEqual(DeepLink.path(from: url), "notes/日本語 メモ&その他.md")
    }

    func testURL_RejectsOtherSchemeHostOrMissingPath() {
        XCTAssertNil(DeepLink.path(from: URL(string: "https://open?path=a.md")!))
        XCTAssertNil(DeepLink.path(from: URL(string: "myownjournal://edit?path=a.md")!))
        XCTAssertNil(DeepLink.path(from: URL(string: "myownjournal://open")!))
        XCTAssertNil(DeepLink.path(from: URL(string: "myownjournal://open?path=")!))
    }
}
