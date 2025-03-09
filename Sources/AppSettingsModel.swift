import Foundation

// 設定データモデル
struct AppSettings {
    var githubPAT: String
    var repositoryName: String
    var journalRule: String
    var lastSpotlightIndexUpdate: Date?
    var indexedFilesCount: Int = 0
    
    // 設定が完了しているかどうかを判断するメソッド
    var isConfigured: Bool {
        return !githubPAT.isEmpty && !repositoryName.isEmpty && !journalRule.isEmpty
    }
    
    // UserDefaultsのキー
    private static let githubPATKey = "githubPAT"
    private static let repositoryNameKey = "repositoryName"
    private static let journalRuleKey = "journalRule"
    private static let lastSpotlightIndexUpdateKey = "lastSpotlightIndexUpdate"
    private static let indexedFilesCountKey = "indexedFilesCount"
    
    // 初期値
    static let defaultSettings = AppSettings(
        githubPAT: "",
        repositoryName: "",
        journalRule: "log/YYYY/MM/DD.md",
        lastSpotlightIndexUpdate: nil,
        indexedFilesCount: 0
    )
    
    // UserDefaultsから設定を読み込む
    static func loadFromUserDefaults() -> AppSettings {
        let userDefaults = UserDefaults.standard
        
        let lastUpdateDate: Date? = userDefaults.object(forKey: lastSpotlightIndexUpdateKey) as? Date
        let indexedCount = userDefaults.integer(forKey: indexedFilesCountKey)
        
        return AppSettings(
            githubPAT: userDefaults.string(forKey: githubPATKey) ?? "",
            repositoryName: userDefaults.string(forKey: repositoryNameKey) ?? "",
            journalRule: userDefaults.string(forKey: journalRuleKey) ?? "log/YYYY/MM/DD.md",
            lastSpotlightIndexUpdate: lastUpdateDate,
            indexedFilesCount: indexedCount
        )
    }
    
    // UserDefaultsに設定を保存する
    func saveToUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(githubPAT, forKey: AppSettings.githubPATKey)
        userDefaults.set(repositoryName, forKey: AppSettings.repositoryNameKey)
        userDefaults.set(journalRule, forKey: AppSettings.journalRuleKey)
        userDefaults.set(indexedFilesCount, forKey: AppSettings.indexedFilesCountKey)
        
        if let lastUpdate = lastSpotlightIndexUpdate {
            userDefaults.set(lastUpdate, forKey: AppSettings.lastSpotlightIndexUpdateKey)
        }
    }
    
    // Spotlightインデックスの更新日時を記録
    mutating func updateSpotlightIndexTimestamp() {
        lastSpotlightIndexUpdate = Date()
        saveToUserDefaults()
    }
    
    // 最後のSpotlightインデックス更新からの経過時間を取得（フォーマット済み）
    func getLastSpotlightUpdateFormatted() -> String {
        guard let lastUpdate = lastSpotlightIndexUpdate else {
            return "未更新"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}