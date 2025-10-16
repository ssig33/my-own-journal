import Foundation
import SwiftUI

// ジャーナル関連のビジネスロジックを担当するViewModel
class JournalViewModel: ObservableObject {
    @Published var journal = JournalEntry.empty
    @Published var inputText = ""
    @Published var isSubmitting = false
    @Published var showCommitInfo = false
    
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
        showCommitInfo = false
        
        // ファイルをリモートから取得
        let path = githubService.getJournalPath()
        githubService.getFileContentAndSHA(path: path) { [weak self] content, sha, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isSubmitting = false
                self.journal.error = error
                return
            }
            
            // 取得したコンテンツに新しい内容を追加
            let currentContent = content ?? self.githubService.createDefaultJournalContent()
            let newEntry = self.inputText
            let newContent = self.githubService.formatJournalEntry(currentContent: currentContent, newEntry: newEntry)
            
            // 取得したSHAの上にコミット
            self.githubService.updateFileContent(path: path, content: newContent, sha: sha) { [weak self] success, error, statusCode in
                guard let self = self else { return }
                
                if success {
                    // 成功した場合、入力フィールドをクリア
                    self.inputText = ""
                    
                    // 即座に完了してコミット完了通知を表示
                    self.isSubmitting = false
                    self.showCommitInfo = true
                    
                    // ジャーナル内容を更新（リロードではなく直接更新）
                    self.journal.content = newContent
                    
                    // 3秒後に通知を自動的に非表示にする
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            self.showCommitInfo = false
                        }
                    }
                } else if let error = error {
                    self.isSubmitting = false
                    self.journal.error = error
                    
                    // 409エラー（コンフリクト）の場合は特別なメッセージを表示
                    if statusCode == 409 {
                        self.journal.error = "ファイルが他の場所で編集されています。最新の内容を確認してから再度お試しください。"
                    }
                }
            }
        }
    }
    
    // 現在のジャーナルのパスを取得
    func getJournalPath() -> String {
        return githubService.getJournalPath()
    }
}