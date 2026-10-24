import Foundation
import CoreSpotlight

// 外部からリポジトリ内のファイルを開くためのディープリンク
// 形式: myownjournal://open?path=<リポジトリ内のパス>
enum DeepLink {
    static let scheme = "myownjournal"
    static let openHost = "open"

    // ファイルのパスからディープリンクの URL を作る
    static func url(forPath path: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = openHost
        components.queryItems = [URLQueryItem(name: "path", value: path)]
        return components.url
    }

    // ディープリンクの URL からファイルのパスを取り出す
    static func path(from url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == openHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let value = components.queryItems?.first(where: { $0.name == "path" })?.value else {
            return nil
        }
        return normalize(value)
    }

    // Spotlight の検索結果から渡された NSUserActivity からファイルのパスを取り出す
    // Spotlight の項目は uniqueIdentifier にファイルのパスを入れている
    static func path(from userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        return normalize(identifier)
    }

    // 先頭の / を取り除く。空ならファイルとして扱えないので nil
    private static func normalize(_ path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? nil : trimmed
    }
}
