import Foundation

// 設定データモデル
struct AppSettings {
    var githubPAT: String
    var repositoryName: String
    var journalRule: String
    
    // 設定が完了しているかどうかを判断するメソッド
    var isConfigured: Bool {
        return !githubPAT.isEmpty && !repositoryName.isEmpty && !journalRule.isEmpty
    }
    
    // UserDefaultsのキー
    private static let githubPATKey = "githubPAT"
    private static let repositoryNameKey = "repositoryName"
    private static let journalRuleKey = "journalRule"
    
    // 初期値
    static let defaultSettings = AppSettings(
        githubPAT: "",
        repositoryName: "",
        journalRule: "log/YYYY/MM/DD.md"
    )
    
    // UserDefaultsから設定を読み込む
    static func loadFromUserDefaults() -> AppSettings {
        let userDefaults = UserDefaults.standard
        
        return AppSettings(
            githubPAT: userDefaults.string(forKey: githubPATKey) ?? "",
            repositoryName: userDefaults.string(forKey: repositoryNameKey) ?? "",
            journalRule: userDefaults.string(forKey: journalRuleKey) ?? "log/YYYY/MM/DD.md"
        )
    }
    
    // UserDefaultsに設定を保存する
    func saveToUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(githubPAT, forKey: AppSettings.githubPATKey)
        userDefaults.set(repositoryName, forKey: AppSettings.repositoryNameKey)
        userDefaults.set(journalRule, forKey: AppSettings.journalRuleKey)
    }
}