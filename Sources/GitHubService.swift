import Foundation

// GitHub APIとの通信を担当するサービスクラス
class GitHubService {
    private let settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    // リポジトリ内のファイル内容を検索
    func searchContent(query: String, completion: @escaping ([SearchResult], String?) -> Void) {
        guard settings.isConfigured else {
            completion([], "設定が完了していません")
            return
        }
        
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            completion([], "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。")
            return
        }
        
        // 検索クエリが空の場合はルートディレクトリを表示
        if query.isEmpty {
            searchFiles(query: "", completion: completion)
            return
        }
        
        // GitHub Search APIのクエリを構築
        let searchQuery = "\(query) repo:\(owner)/\(repo) language:markdown"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.github.com/search/code?q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            completion([], "URLの生成に失敗しました")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion([], "ネットワークエラー: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion([], "不明なレスポンス")
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion([], "データが空です")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let items = json["items"] as? [[String: Any]] {
                            
                            var results: [SearchResult] = []
                            
                            for item in items {
                                if let name = item["name"] as? String,
                                   let path = item["path"] as? String,
                                   let htmlUrl = item["html_url"] as? String {
                                    
                                    let result = SearchResult(name: name, path: path, type: .file)
                                    results.append(result)
                                }
                            }
                            
                            completion(results, nil)
                        } else {
                            completion([], "検索結果の解析に失敗しました")
                        }
                    } catch {
                        completion([], "JSONの解析エラー: \(error.localizedDescription)")
                    }
                    
                case 401:
                    completion([], "認証エラー: GitHub PATが無効です")
                    
                case 403:
                    completion([], "APIレート制限に達しました。しばらく待ってから再試行してください。")
                    
                case 404:
                    completion([], "検索結果が見つかりません")
                    
                default:
                    completion([], "APIエラー: ステータスコード \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // リポジトリ内のファイルを検索
    func searchFiles(query: String, completion: @escaping ([SearchResult], String?) -> Void) {
        guard settings.isConfigured else {
            completion([], "設定が完了していません")
            return
        }
        
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            completion([], "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。")
            return
        }
        
        // クエリが空の場合はルートディレクトリの内容を取得
        let path = query.isEmpty ? "" : query
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            completion([], "URLの生成に失敗しました")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion([], "ネットワークエラー: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion([], "不明なレスポンス")
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion([], "データが空です")
                        return
                    }
                    
                    do {
                        // 配列またはオブジェクトのどちらかを処理
                        if let contentsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            // ディレクトリ内のファイル一覧
                            var results: [SearchResult] = []
                            
                            for item in contentsArray {
                                if let name = item["name"] as? String,
                                   let path = item["path"] as? String,
                                   let type = item["type"] as? String {
                                    
                                    let fileType: SearchResult.FileType = (type == "dir") ? .directory : .file
                                    results.append(SearchResult(name: name, path: path, type: fileType))
                                }
                            }
                            
                            completion(results, nil)
                        } else if let fileInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // 単一ファイルの情報
                            if let name = fileInfo["name"] as? String,
                               let path = fileInfo["path"] as? String,
                               let type = fileInfo["type"] as? String {
                                
                                let fileType: SearchResult.FileType = (type == "dir") ? .directory : .file
                                let result = SearchResult(name: name, path: path, type: fileType)
                                completion([result], nil)
                            } else {
                                completion([], "ファイル情報の解析に失敗しました")
                            }
                        } else {
                            completion([], "JSONの解析に失敗しました")
                        }
                    } catch {
                        completion([], "JSONの解析エラー: \(error.localizedDescription)")
                    }
                    
                case 401:
                    completion([], "認証エラー: GitHub PATが無効です")
                    
                case 404:
                    completion([], "ファイルまたはディレクトリが見つかりません")
                    
                default:
                    completion([], "APIエラー: ステータスコード \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // ファイルの内容を取得
    func getFileContent(path: String, completion: @escaping (String?, String?) -> Void) {
        guard settings.isConfigured else {
            completion(nil, "設定が完了していません")
            return
        }
        
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            completion(nil, "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。")
            return
        }
        
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, "URLの生成に失敗しました")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "ネットワークエラー: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(nil, "不明なレスポンス")
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion(nil, "データが空です")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let content = json["content"] as? String {
                            
                            // Base64デコード
                            if let decodedData = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")),
                               let decodedString = String(data: decodedData, encoding: .utf8) {
                                
                                completion(decodedString, nil)
                            } else {
                                completion(nil, "コンテンツのデコードに失敗しました")
                            }
                        } else {
                            completion(nil, "JSONの解析に失敗しました")
                        }
                    } catch {
                        completion(nil, "JSONの解析エラー: \(error.localizedDescription)")
                    }
                    
                case 401:
                    completion(nil, "認証エラー: GitHub PATが無効です")
                    
                case 404:
                    completion(nil, "ファイルが見つかりません")
                    
                default:
                    completion(nil, "APIエラー: ステータスコード \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // 現在の日付を取得（午前2時までは前日の日付として扱う）
    func getCurrentDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // 午前2時までは前日の日付として扱う
        if hour < 2 {
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        
        return now
    }
    
    // 日付に基づいてジャーナルファイルのパスを生成
    func getJournalPath() -> String {
        let date = getCurrentDate()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        var path = settings.journalRule
        path = path.replacingOccurrences(of: "YYYY", with: String(format: "%04d", year))
        path = path.replacingOccurrences(of: "MM", with: String(format: "%02d", month))
        path = path.replacingOccurrences(of: "DD", with: String(format: "%02d", day))
        
        return path
    }
    
    // デフォルトのジャーナル内容を生成
    func createDefaultJournalContent() -> String {
        let date = getCurrentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "# \(dateFormatter.string(from: date))"
    }
    
    // 入力されたテキストをフォーマットする
    func formatJournalEntry(currentContent: String, newEntry: String) -> String {
        let lines = newEntry.split(separator: "\n")
        
        if lines.count == 1 {
            // 1行の場合は "- テキスト" の形式で追加
            return "\(currentContent)\n- \(newEntry)"
        } else {
            // 複数行の場合は "-----" で区切って追加
            return "\(currentContent)\n-----\n\(newEntry)"
        }
    }
    
    // GitHub APIを使用してジャーナルファイルを取得
    func loadJournal(completion: @escaping (JournalEntry) -> Void) {
        guard settings.isConfigured else {
            completion(JournalEntry(content: "", isLoading: false, error: "設定が完了していません"))
            return
        }
        
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            completion(JournalEntry(content: "", isLoading: false, error: "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。"))
            return
        }
        
        let path = getJournalPath()
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            completion(JournalEntry(content: "", isLoading: false, error: "URLの生成に失敗しました"))
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "GET"
        request.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // キャッシュを無効化するヘッダーを追加
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "If-None-Match") // ETAGを無視
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(JournalEntry(content: "", isLoading: false, error: "ネットワークエラー: \(error.localizedDescription)"))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(JournalEntry(content: "", isLoading: false, error: "不明なレスポンス"))
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion(JournalEntry(content: "", isLoading: false, error: "データが空です"))
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let content = json["content"] as? String {
                            
                            // Base64デコード
                            if let decodedData = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")),
                               let decodedString = String(data: decodedData, encoding: .utf8) {
                                
                                completion(JournalEntry(content: decodedString, isLoading: false, error: nil))
                            } else {
                                completion(JournalEntry(content: "", isLoading: false, error: "コンテンツのデコードに失敗しました"))
                            }
                        } else {
                            completion(JournalEntry(content: "", isLoading: false, error: "JSONの解析に失敗しました"))
                        }
                    } catch {
                        completion(JournalEntry(content: "", isLoading: false, error: "JSONの解析エラー: \(error.localizedDescription)"))
                    }
                    
                case 401:
                    completion(JournalEntry(content: "", isLoading: false, error: "認証エラー: GitHub PATが無効です"))
                    
                case 404:
                    // ファイルが存在しない場合は、デフォルトの内容を設定
                    completion(JournalEntry(content: self.createDefaultJournalContent(), isLoading: false, error: nil))
                    
                default:
                    completion(JournalEntry(content: "", isLoading: false, error: "APIエラー: ステータスコード \(httpResponse.statusCode)"))
                }
            }
        }.resume()
    }
    
    // GitHub APIを使用してファイルを更新
    func updateJournalFile(content: String, completion: @escaping (Bool, String?) -> Void) {
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            completion(false, "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。")
            return
        }
        
        let path = getJournalPath()
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            completion(false, "URLの生成に失敗しました")
            return
        }
        
        // まず現在のファイル情報を取得（SHAが必要）
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
        getRequest.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: getRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "ネットワークエラー: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "不明なレスポンス")
                }
                return
            }
            
            // ファイルが存在しない場合は新規作成
            let fileExists = httpResponse.statusCode == 200
            var sha: String? = nil
            
            if fileExists, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        sha = json["sha"] as? String
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, "JSONの解析エラー: \(error.localizedDescription)")
                    }
                    return
                }
            }
            
            // ファイルの更新または作成
            var putRequest = URLRequest(url: url)
            putRequest.httpMethod = "PUT"
            putRequest.addValue("token \(self.settings.githubPAT)", forHTTPHeaderField: "Authorization")
            putRequest.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            
            // リクエストボディの作成
            var requestBody: [String: Any] = [
                "message": "Add journal",
                "content": Data(content.utf8).base64EncodedString()
            ]
            
            if let sha = sha {
                requestBody["sha"] = sha
            }
            
            do {
                putRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                DispatchQueue.main.async {
                    completion(false, "リクエストの作成に失敗しました: \(error.localizedDescription)")
                }
                return
            }
            
            // PUTリクエストの送信
            URLSession.shared.dataTask(with: putRequest) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, "ネットワークエラー: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(false, "不明なレスポンス")
                        return
                    }
                    
                    switch httpResponse.statusCode {
                    case 200, 201:
                        completion(true, nil)
                        
                    case 401:
                        completion(false, "認証エラー: GitHub PATが無効です")
                        
                    case 422:
                        completion(false, "不正なリクエスト: ファイルの更新に失敗しました")
                        
                    default:
                        completion(false, "APIエラー: ステータスコード \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        }.resume()
    }
}