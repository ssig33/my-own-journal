import Foundation
import SwiftUI

// ジャーナル関連のビジネスロジックを担当するViewModel
class JournalViewModel: ObservableObject {
    @Published var journal = JournalEntry.empty
    @Published var inputText = ""
    @Published var isSubmitting = false
    
    private let githubService: GitHubService
    
    init(settings: AppSettings) {
        self.githubService = GitHubService(settings: settings)
    }
    
    // ジャーナルを読み込む
    func loadJournal() {
        journal.isLoading = true
        journal.error = nil
        
        githubService.loadJournal { [weak self] result in
            guard let self = self else { return }
            self.journal = result
        }
    }
    
    // ジャーナルを送信する
    func submitJournal() {
        guard !inputText.isEmpty else { return }
        
        isSubmitting = true
        
        // 現在のジャーナル内容を取得し、新しい内容を追加
        let currentContent = journal.content
        let newContent = githubService.formatJournalEntry(currentContent: currentContent, newEntry: inputText)
        
        // GitHub APIを使用してファイルを更新
        githubService.updateJournalFile(content: newContent) { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                // 成功した場合、入力フィールドをクリア
                self.inputText = ""
                
                // 送信中の状態を維持したまま5秒間待機
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    // 5秒後に isSubmitting を false にしてリロード
                    self.isSubmitting = false
                    self.loadJournal()
                }
            } else if let error = error {
                self.isSubmitting = false
                self.journal.error = error
            }
        }
    }
}