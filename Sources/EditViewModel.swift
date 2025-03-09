import Foundation
import SwiftUI

// ジャーナル編集のビジネスロジックを担当するViewModel
class EditViewModel: ObservableObject {
    @Published var journalContent = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showPreview = false
    
    private let githubService: GitHubService
    private let originalContent: String
    
    init(settings: AppSettings, initialContent: String) {
        self.githubService = GitHubService(settings: settings)
        self.journalContent = initialContent
        self.originalContent = initialContent
    }
    
    // ジャーナルを読み込む
    func loadJournal() {
        isLoading = true
        error = nil
        
        githubService.loadJournal { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = result.error {
                self.error = error
            } else {
                self.journalContent = result.content
            }
        }
    }
    
    // 編集したジャーナルを保存する
    func saveJournal(completion: @escaping (Bool) -> Void) {
        guard !journalContent.isEmpty else { return }
        
        isSaving = true
        error = nil
        
        // GitHub APIを使用してファイルを更新
        githubService.updateJournalFile(content: journalContent) { [weak self] success, error in
            guard let self = self else { return }
            
            self.isSaving = false
            
            if success {
                completion(true)
            } else if let error = error {
                self.error = error
                completion(false)
            } else {
                completion(false)
            }
        }
    }
    
    // 編集したファイルを保存する（パスを指定）
    func saveFile(path: String, completion: @escaping (Bool) -> Void) {
        guard !journalContent.isEmpty else { return }
        
        isSaving = true
        error = nil
        
        // GitHub APIを使用してファイルを更新
        githubService.updateFileContent(path: path, content: journalContent) { [weak self] success, error in
            guard let self = self else { return }
            
            self.isSaving = false
            
            if success {
                completion(true)
            } else if let error = error {
                self.error = error
                completion(false)
            } else {
                completion(false)
            }
        }
    }
    
    // 変更があるかどうかを確認
    var hasChanges: Bool {
        return journalContent != originalContent
    }
    
    // プレビューの切り替え
    func togglePreview() {
        showPreview.toggle()
    }
}