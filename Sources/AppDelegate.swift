import SwiftUI
import Foundation

// ジャーナルデータモデル
struct JournalEntry {
    var content: String
    var isLoading: Bool
    var error: String?
    
    static let empty = JournalEntry(content: "", isLoading: false, error: nil)
}

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

// 設定画面
struct SettingsView: View {
    @Binding var settings: AppSettings
    @Binding var isSettingsCompleted: Bool
    
    @State private var githubPAT: String
    @State private var repositoryName: String
    @State private var journalRule: String
    
    init(settings: Binding<AppSettings>, isSettingsCompleted: Binding<Bool>) {
        self._settings = settings
        self._isSettingsCompleted = isSettingsCompleted
        
        // 初期値を設定
        _githubPAT = State(initialValue: settings.wrappedValue.githubPAT)
        _repositoryName = State(initialValue: settings.wrappedValue.repositoryName)
        _journalRule = State(initialValue: settings.wrappedValue.journalRule)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub設定")) {
                    TextField("GitHub Personal Access Token", text: $githubPAT)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("リポジトリ名", text: $repositoryName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section(header: Text("ジャーナル設定")) {
                    TextField("ジャーナルの記録ルール", text: $journalRule)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("例: log/YYYY/MM/DD.md")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !isJournalRuleValid && !journalRule.isEmpty {
                        Text("※ YYYY, MM, DD が含まれている必要があります")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("※ YYYY, MM, DD が含まれている必要があります")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if !journalRule.isEmpty && isJournalRuleValid {
                        Text("今日の場合：\(expandJournalRule(journalRule))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button("保存") {
                        saveSettings()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("設定")
        }
    }
    
    // フォームが有効かどうかを判断するプロパティ
    private var isFormValid: Bool {
        return !githubPAT.isEmpty && !repositoryName.isEmpty && isJournalRuleValid
    }
    
    // ジャーナルルールが有効かどうかを判断するプロパティ
    private var isJournalRuleValid: Bool {
        return !journalRule.isEmpty &&
               journalRule.contains("YYYY") &&
               journalRule.contains("MM") &&
               journalRule.contains("DD")
    }
    
    // ジャーナルルールを今日の日付で展開するメソッド
    private func expandJournalRule(_ rule: String) -> String {
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
    private func saveSettings() {
        settings.githubPAT = githubPAT
        settings.repositoryName = repositoryName
        settings.journalRule = journalRule
        
        settings.saveToUserDefaults()
        isSettingsCompleted = settings.isConfigured
    }
}

// メイン画面
struct MainView: View {
    @State private var journal = JournalEntry.empty
    @State private var settings = AppSettings.loadFromUserDefaults()
    
    var body: some View {
        VStack {
            if journal.isLoading {
                ProgressView("読み込み中...")
                    .padding()
            } else if let error = journal.error {
                VStack {
                    Text("エラーが発生しました")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.bottom, 4)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding(.bottom)
                    
                    Button("再読み込み") {
                        loadJournal()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else {
                ScrollView {
                    Text(journal.content)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear {
            loadJournal()
        }
    }
    
    // 現在の日付を取得（午前2時までは前日の日付として扱う）
    private func getCurrentDate() -> Date {
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
    private func getJournalPath() -> String {
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
    private func createDefaultJournalContent() -> String {
        let date = getCurrentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "# \(dateFormatter.string(from: date))"
    }
    
    // GitHub APIを使用してジャーナルファイルを取得
    private func loadJournal() {
        guard settings.isConfigured else {
            journal.error = "設定が完了していません"
            return
        }
        
        journal.isLoading = true
        journal.error = nil
        
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            journal.isLoading = false
            journal.error = "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。"
            return
        }
        
        let path = getJournalPath()
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            journal.isLoading = false
            journal.error = "URLの生成に失敗しました"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("token \(settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                journal.isLoading = false
                
                if let error = error {
                    journal.error = "ネットワークエラー: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    journal.error = "不明なレスポンス"
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        journal.error = "データが空です"
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let content = json["content"] as? String {
                            
                            // Base64デコード
                            if let decodedData = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")),
                               let decodedString = String(data: decodedData, encoding: .utf8) {
                                journal.content = decodedString
                            } else {
                                journal.error = "コンテンツのデコードに失敗しました"
                            }
                        } else {
                            journal.error = "JSONの解析に失敗しました"
                        }
                    } catch {
                        journal.error = "JSONの解析エラー: \(error.localizedDescription)"
                    }
                    
                case 401:
                    journal.error = "認証エラー: GitHub PATが無効です"
                    
                case 404:
                    // ファイルが存在しない場合は、デフォルトの内容を設定
                    journal.content = createDefaultJournalContent()
                    
                default:
                    journal.error = "APIエラー: ステータスコード \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}

// コンテンツビュー（ナビゲーション制御）
struct ContentView: View {
    @State private var settings = AppSettings.loadFromUserDefaults()
    @State private var isSettingsCompleted = AppSettings.loadFromUserDefaults().isConfigured
    @State private var selectedTab = 0
    
    var body: some View {
        if !isSettingsCompleted {
            // 設定が完了していない場合は設定画面のみ表示
            SettingsView(settings: $settings, isSettingsCompleted: $isSettingsCompleted)
        } else {
            // 設定が完了している場合はタブビューを表示
            TabView(selection: $selectedTab) {
                MainView()
                    .tabItem {
                        Label("ジャーナル", systemImage: "book.fill")
                    }
                    .tag(0)
                
                SettingsView(settings: $settings, isSettingsCompleted: $isSettingsCompleted)
                    .tabItem {
                        Label("設定", systemImage: "gear")
                    }
                    .tag(1)
            }
        }
    }
}

#Preview {
    ContentView()
}

@main
struct MyOwnJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
