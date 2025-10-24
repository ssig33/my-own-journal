import Foundation
import SwiftUI

// 検索機能のビジネスロジックを担当するViewModel
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var selectedFile: SearchResult?
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var showingResults = false
    @Published var showingFileContent = false
    @Published var showingEditView = false
    @Published var currentPath = ""
    
    // 新規ファイル作成関連
    @Published var showingNewFileForm = false
    @Published var newFileName = ""
    @Published var isCreatingFile = false
    
    private let githubService: GitHubService
    
    init(settings: AppSettings) {
        self.githubService = GitHubService(settings: settings)
    }
    
    // 親ディレクトリに戻る
    func navigateToParentDirectory() {
        if currentPath.isEmpty {
            return // すでにルートディレクトリにいる場合は何もしない
        }
        
        // パスの最後のスラッシュを見つける
        if let lastSlashIndex = currentPath.lastIndex(of: "/") {
            // 親ディレクトリのパスを取得
            let parentPath = currentPath[..<lastSlashIndex]
            
            // 空文字列の場合はルートディレクトリ
            if parentPath.isEmpty {
                searchRootDirectory()
            } else {
                // 親ディレクトリの内容を取得
                getDirectoryContents(path: String(parentPath))
            }
        } else {
            // スラッシュがない場合はルートディレクトリに戻る
            searchRootDirectory()
        }
    }
    
    // 検索を実行
    func search() {
        guard !searchQuery.isEmpty else {
            // 空の検索クエリの場合はルートディレクトリを検索
            searchRootDirectory()
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // ファイル内容を検索
        githubService.searchContent(query: searchQuery) { [weak self] results, error in
            guard let self = self else { return }
            
            self.isSearching = false
            
            if let error = error {
                self.errorMessage = error
                self.searchResults = []
            } else {
                self.searchResults = results
                self.showingResults = true
                self.showingFileContent = false
            }
        }
    }
    
    // ルートディレクトリを検索
    private func searchRootDirectory() {
        isSearching = true
        errorMessage = nil
        currentPath = ""
        
        githubService.searchFiles(query: "") { [weak self] results, error in
            guard let self = self else { return }
            
            self.isSearching = false
            
            if let error = error {
                self.errorMessage = error
                self.searchResults = []
            } else {
                self.searchResults = results
                self.showingResults = true
                self.showingFileContent = false
            }
        }
    }
    
    // ディレクトリの内容を取得
    func getDirectoryContents(path: String) {
        isSearching = true
        errorMessage = nil
        currentPath = path
        
        githubService.searchFiles(query: path) { [weak self] results, error in
            guard let self = self else { return }
            
            self.isSearching = false
            
            if let error = error {
                self.errorMessage = error
                self.searchResults = []
            } else {
                self.searchResults = results
                self.showingResults = true
                self.showingFileContent = false
            }
        }
    }
    
    // ファイルを選択
    func selectFile(_ file: SearchResult) {
        if file.type == .directory {
            // ディレクトリの場合は内容を取得
            getDirectoryContents(path: file.path)
        } else {
            // ファイルの場合は内容を取得
            isSearching = true
            errorMessage = nil
            
            var updatedFile = file
            updatedFile.isLoading = true
            selectedFile = updatedFile
            
            githubService.getFileContent(path: file.path) { [weak self] content, error in
                guard let self = self else { return }
                
                self.isSearching = false
                
                if let error = error {
                    updatedFile.error = error
                    updatedFile.isLoading = false
                    self.selectedFile = updatedFile
                } else if let content = content {
                    updatedFile.content = content
                    updatedFile.isLoading = false
                    self.selectedFile = updatedFile
                    self.showingFileContent = true
                }
            }
        }
    }
    
    // 検索結果表示に戻る
    func backToResults() {
        showingFileContent = false
    }
    
    // パスを指定してファイルを開く（Spotlight検索結果からの遷移用）
    func openFileByPath(_ path: String) {
        isSearching = true
        errorMessage = nil
        
        // パスからファイル名を抽出
        let components = path.split(separator: "/")
        let fileName = components.last.map(String.init) ?? "Unknown"
        
        // 仮のSearchResultを作成
        let file = SearchResult(name: fileName, path: path, type: .file)
        
        // ファイルの内容を取得
        var updatedFile = file
        updatedFile.isLoading = true
        selectedFile = updatedFile
        
        githubService.getFileContent(path: path) { [weak self] content, error in
            guard let self = self else { return }
            
            self.isSearching = false
            
            if let error = error {
                updatedFile.error = error
                updatedFile.isLoading = false
                self.selectedFile = updatedFile
            } else if let content = content {
                updatedFile.content = content
                updatedFile.isLoading = false
                self.selectedFile = updatedFile
                self.showingFileContent = true
                self.showingResults = true
                
                // 親ディレクトリのパスを設定
                if let lastSlashIndex = path.lastIndex(of: "/") {
                    self.currentPath = String(path[..<lastSlashIndex])
                } else {
                    self.currentPath = ""
                }
            }
        }
    }
    
    // 新規ファイル作成フォームを表示
    func showNewFileForm() {
        // 現在のパスを初期値として設定
        if !currentPath.isEmpty {
            newFileName = currentPath + "/"
        } else {
            newFileName = ""
        }
        showingNewFileForm = true
    }
    
    // 新規ファイル作成フォームをキャンセル
    func cancelNewFileForm() {
        showingNewFileForm = false
        newFileName = ""
    }
    
    // 新規ファイルを作成
    func createNewFile(completion: @escaping (Bool, String?) -> Void) {
        guard !newFileName.isEmpty else {
            errorMessage = "ファイル名を入力してください"
            completion(false, nil)
            return
        }

        // ファイル名の処理
        var processedFileName = newFileName

        // 末尾が / で終わっている場合は index.md を追加
        if processedFileName.hasSuffix("/") {
            processedFileName += "index.md"
        }
        // .md で終わっていない場合は .md を追加
        else if !processedFileName.hasSuffix(".md") {
            processedFileName += ".md"
        }

        isCreatingFile = true
        errorMessage = nil

        // 空のファイルを作成
        let emptyContent = "# " + (processedFileName.split(separator: "/").last?.replacingOccurrences(of: ".md", with: "") ?? "New File")

        githubService.updateFileContent(path: processedFileName, content: emptyContent) { [weak self] success, error, statusCode in
            guard let self = self else { return }

            self.isCreatingFile = false

            if success {
                self.showingNewFileForm = false
                self.newFileName = ""

                // 作成したファイルのパスをコールバックで返す
                completion(true, processedFileName)
            } else if let error = error {
                self.errorMessage = error
                completion(false, nil)
            } else {
                self.errorMessage = "ファイルの作成に失敗しました"
                completion(false, nil)
            }
        }
    }
}