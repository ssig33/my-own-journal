import Foundation
import SwiftUI

// ジャーナル編集のビジネスロジックを担当するViewModel
class EditViewModel: ObservableObject {
    @Published var journalContent = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showPreview = false
    @Published var conflictDetected = false  // コンフリクト検出フラグ
    @Published var latestContent: String?    // コンフリクト時の最新コンテンツ
    
    private let githubService: GitHubService
    private var originalContent: String  // letからvarに変更
    private var fileSHA: String?  // ファイルのSHA
    
    init(settings: AppSettings, initialContent: String) {
        self.githubService = GitHubService(settings: settings)
        self.journalContent = initialContent
        self.originalContent = initialContent
    }
    
    // ファイルの最新内容とSHAを取得
    func refreshFileContent(path: String) {
        isLoading = true
        error = nil
        conflictDetected = false
        
        githubService.getFileContentAndSHA(path: path) { [weak self] content, sha, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error
            } else if let content = content, let sha = sha {
                self.journalContent = content
                self.originalContent = content
                self.fileSHA = sha
            }
        }
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
        conflictDetected = false
        
        // GitHub APIを使用してファイルを更新
        githubService.updateJournalFile(content: journalContent) { [weak self] success, error, statusCode in
            guard let self = self else { return }
            
            self.isSaving = false
            
            if success {
                completion(true)
            } else if statusCode == 409 {  // コンフリクト検出
                self.handleConflict(path: self.githubService.getJournalPath())
                completion(false)
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
        conflictDetected = false
        
        // GitHub APIを使用してファイルを更新（SHAを渡す）
        githubService.updateFileContent(path: path, content: journalContent, sha: fileSHA) { [weak self] success, error, statusCode in
            guard let self = self else { return }
            
            self.isSaving = false
            
            if success {
                completion(true)
            } else if statusCode == 409 {  // コンフリクト検出
                self.handleConflict(path: path)
                completion(false)
            } else if let error = error {
                self.error = error
                completion(false)
            } else {
                completion(false)
            }
        }
    }
    
    // コンフリクト処理
    private func handleConflict(path: String) {
        conflictDetected = true
        
        // 最新のファイル内容を再取得
        githubService.getFileContentAndSHA(path: path) { [weak self] content, sha, error in
            guard let self = self else { return }
            
            if let content = content {
                self.latestContent = content
                self.fileSHA = sha  // 最新のSHAを更新
            }
            
            // コンフリクトメッセージ
            self.error = "ファイルが他の場所で編集されています。最新の内容を確認し、必要な変更を加えてから再度保存してください。"
        }
    }
    
    // 最新の内容を採用
    func acceptLatestContent() {
        if let latestContent = latestContent {
            journalContent = latestContent
            originalContent = latestContent
            conflictDetected = false
            error = nil
        }
    }
    
    // 自分の変更を維持（最新のSHAで保存）
    func keepMyChanges() {
        conflictDetected = false
        error = nil
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