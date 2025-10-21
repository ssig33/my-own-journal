import Foundation
import CoreSpotlight

// Spotlight検索インデックスの管理を担当するサービスクラス
class SpotlightService {
    private let githubService: GitHubService
    
    init(settings: AppSettings) {
        self.githubService = GitHubService(settings: settings)
    }
    
    // リポジトリ内のファイルをクロールしてSpotlightインデックスを更新
    func updateSpotlightIndex(completion: @escaping (Bool, String?, Int) -> Void) {
        // まず既存のインデックスを削除
        deleteAllSpotlightIndices { [weak self] success, error in
            guard let self = self, success else {
                completion(false, error ?? "インデックスの削除に失敗しました", 0)
                return
            }
            
            // リポジトリのルートディレクトリからクロール開始
            self.crawlRepositoryAndIndex(path: "", indexedCount: 0, completion: completion)
        }
    }
    
    // リポジトリを再帰的にクロールしてインデックスを作成
    private func crawlRepositoryAndIndex(path: String, indexedCount: Int, completion: @escaping (Bool, String?, Int) -> Void) {
        githubService.searchFiles(query: path) { [weak self] results, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, "リポジトリのクロールに失敗しました: \(error)", indexedCount)
                return
            }
            
            // ディレクトリとファイルを分ける
            let directories = results.filter { $0.type == .directory }
            let files = results.filter { $0.type == .file }
            
            // ファイルの内容を取得してインデックスに追加
            let group = DispatchGroup()
            var indexItems: [SpotlightIndexItem] = []
            var errors: [String] = []
            
            for file in files {
                // Markdownファイルのみインデックスに追加
                if file.name.hasSuffix(".md") {
                    group.enter()
                    self.githubService.getFileContent(path: file.path) { content, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            errors.append("ファイル '\(file.path)' の取得に失敗: \(error)")
                        } else if let content = content {
                            let indexItem = SpotlightIndexItem(
                                name: file.name,
                                path: file.path,
                                content: content
                            )
                            indexItems.append(indexItem)
                        }
                    }
                }
            }
            
            // すべてのファイル処理が完了するのを待つ
            group.notify(queue: .main) {
                // インデックスに追加
                self.addItemsToSpotlightIndex(items: indexItems) { success, indexError in
                    if !success {
                        errors.append(indexError ?? "インデックスの追加に失敗しました")
                    }
                    
                    let currentIndexedCount = indexedCount + indexItems.count
                    
                    // サブディレクトリを再帰的に処理
                    if directories.isEmpty {
                        // ディレクトリがなければ完了
                        if errors.isEmpty {
                            completion(true, nil, currentIndexedCount)
                        } else {
                            completion(false, errors.joined(separator: "\n"), currentIndexedCount)
                        }
                    } else {
                        // サブディレクトリを処理
                        let subDirGroup = DispatchGroup()
                        var totalIndexedCount = currentIndexedCount
                        
                        for directory in directories {
                            subDirGroup.enter()
                            self.crawlRepositoryAndIndex(path: directory.path, indexedCount: 0) { _, dirError, dirCount in
                                if let dirError = dirError {
                                    errors.append("ディレクトリ '\(directory.path)' の処理に失敗: \(dirError)")
                                }
                                totalIndexedCount += dirCount
                                subDirGroup.leave()
                            }
                        }
                        
                        subDirGroup.notify(queue: .main) {
                            if errors.isEmpty {
                                completion(true, nil, totalIndexedCount)
                            } else {
                                completion(false, errors.joined(separator: "\n"), totalIndexedCount)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Spotlightインデックスにアイテムを追加
    private func addItemsToSpotlightIndex(items: [SpotlightIndexItem], completion: @escaping (Bool, String?) -> Void) {
        guard !items.isEmpty else {
            completion(true, nil)
            return
        }
        
        let searchableItems = items.map { $0.toSearchableItem() }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Spotlightインデックスの更新に失敗しました: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // すべてのSpotlightインデックスを削除
    func deleteAllSpotlightIndices(completion: @escaping (Bool, String?) -> Void) {
        let domainIdentifier = Bundle.main.bundleIdentifier ?? "com.ssig33.MyOwnJournal"
        
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Spotlightインデックスの削除に失敗しました: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // Spotlight検索結果からパスを取得
    static func getPathFromSpotlightUserActivity(_ userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let userInfo = userActivity.userInfo,
              let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        
        // URLからパスを抽出
        if let url = URL(string: urlString), let path = url.path.removingPercentEncoding {
            return path
        }
        
        return nil
    }
}
