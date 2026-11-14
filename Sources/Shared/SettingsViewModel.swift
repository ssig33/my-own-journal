import Foundation
import SwiftUI

// 設定関連のビジネスロジックを担当するViewModel
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var isSettingsCompleted: Bool
    
    @Published var githubPAT: String
    @Published var repositoryName: String
    @Published var journalRule: String
    
    @Published var isUpdatingSpotlightIndex = false
    @Published var spotlightIndexError: String?
    @Published var spotlightIndexSuccess = false
    @Published var indexedFilesCount: Int = 0
    
    private var spotlightService: SpotlightService?
    
    init(settings: AppSettings, isSettingsCompleted: Bool) {
        self.settings = settings
        self.isSettingsCompleted = isSettingsCompleted
        
        // 初期値を設定
        self.githubPAT = settings.githubPAT
        self.repositoryName = settings.repositoryName
        self.journalRule = settings.journalRule
        self.indexedFilesCount = settings.indexedFilesCount
        
        if settings.isConfigured {
            self.spotlightService = SpotlightService(settings: settings)
        }
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
    
    // ジャーナルルールを、ジャーナルの書き込み先と同じ日付（午前2時までは前日）で展開するメソッド
    func expandJournalRule(_ rule: String) -> String {
        GitHubService.expandJournalRule(rule)
    }
    
    // 設定を保存するメソッド
    func saveSettings() {
        settings.githubPAT = githubPAT
        settings.repositoryName = repositoryName
        settings.journalRule = journalRule
        
        settings.saveToUserDefaults()
        isSettingsCompleted = settings.isConfigured
        
        // 設定が完了したらSpotlightServiceを初期化
        if settings.isConfigured {
            self.spotlightService = SpotlightService(settings: settings)
        }
    }
    
    // Spotlight検索インデックスを更新するメソッド
    func updateSpotlightIndex() {
        guard settings.isConfigured else {
            spotlightIndexError = "設定が完了していません"
            return
        }
        
        guard let spotlightService = spotlightService else {
            spotlightService = SpotlightService(settings: settings)
            return
        }
        
        isUpdatingSpotlightIndex = true
        spotlightIndexError = nil
        spotlightIndexSuccess = false
        
        spotlightService.updateSpotlightIndex { [weak self] success, error, count in
            guard let self = self else { return }
            
            self.isUpdatingSpotlightIndex = false
            
            if success {
                var updatedSettings = self.settings
                updatedSettings.updateSpotlightIndexTimestamp()
                updatedSettings.indexedFilesCount = count
                self.settings = updatedSettings
                self.indexedFilesCount = count
                self.spotlightIndexSuccess = true
                
                // 成功メッセージを3秒後に非表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.spotlightIndexSuccess = false
                }
            } else {
                self.spotlightIndexError = error
            }
        }
    }
}