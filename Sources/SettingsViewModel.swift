import Foundation
import SwiftUI

// 設定関連のビジネスロジックを担当するViewModel
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var isSettingsCompleted: Bool
    
    @Published var githubPAT: String
    @Published var repositoryName: String
    @Published var journalRule: String
    
    init(settings: AppSettings, isSettingsCompleted: Bool) {
        self.settings = settings
        self.isSettingsCompleted = isSettingsCompleted
        
        // 初期値を設定
        self.githubPAT = settings.githubPAT
        self.repositoryName = settings.repositoryName
        self.journalRule = settings.journalRule
    }
    
    // フォームが有効かどうかを判断するプロパティ
    var isFormValid: Bool {
        return !githubPAT.isEmpty && !repositoryName.isEmpty && isJournalRuleValid
    }
    
    // ジャーナルルールが有効かどうかを判断するプロパティ
    var isJournalRuleValid: Bool {
        return !journalRule.isEmpty &&
               journalRule.contains("YYYY") &&
               journalRule.contains("MM") &&
               journalRule.contains("DD")
    }
    
    // ジャーナルルールを今日の日付で展開するメソッド
    func expandJournalRule(_ rule: String) -> String {
        let today = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        var expanded = rule
        expanded = expanded.replacingOccurrences(of: "YYYY", with: String(format: "%04d", year))
        expanded = expanded.replacingOccurrences(of: "MM", with: String(format: "%02d", month))
        expanded = expanded.replacingOccurrences(of: "DD", with: String(format: "%02d", day))
        
        return expanded
    }
    
    // 設定を保存するメソッド
    func saveSettings() {
        settings.githubPAT = githubPAT
        settings.repositoryName = repositoryName
        settings.journalRule = journalRule
        
        settings.saveToUserDefaults()
        isSettingsCompleted = settings.isConfigured
    }
}