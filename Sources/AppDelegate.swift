import SwiftUI
import Foundation
import Down
import UIKit

import WebKit

// MarkdownをレンダリングするためのUIViewRepresentable
struct MarkdownView: UIViewRepresentable {
    var markdown: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        
        // スクロールインジケータを非表示にする
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // コンテンツの余白を調整
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let down = Down(markdownString: markdown)
        
        // Markdownをレンダリングするためのオプションを設定
        let options: DownOptions = [.hardBreaks, .safe]
        
        do {
            // MarkdownをHTMLに変換
            let html = try down.toHTML(options)
            
            // スタイルを適用したHTMLを作成
            let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 18px;
                        line-height: 1.5;
                        margin: 0;
                        padding: 0 10px;
                        color: #000;
                        background-color: transparent;
                    }
                    
                    h1 {
                        font-size: 32px;
                        font-weight: bold;
                        margin-top: 20px;
                        margin-bottom: 10px;
                    }
                    
                    h2 {
                        font-size: 28px;
                        font-weight: bold;
                        margin-top: 18px;
                        margin-bottom: 9px;
                    }
                    
                    h3 {
                        font-size: 24px;
                        font-weight: bold;
                        margin-top: 16px;
                        margin-bottom: 8px;
                    }
                    
                    h4 {
                        font-size: 22px;
                        font-weight: bold;
                        margin-top: 14px;
                        margin-bottom: 7px;
                    }
                    
                    h5 {
                        font-size: 20px;
                        font-weight: bold;
                        margin-top: 12px;
                        margin-bottom: 6px;
                    }
                    
                    h6 {
                        font-size: 18px;
                        font-weight: bold;
                        margin-top: 10px;
                        margin-bottom: 5px;
                    }
                    
                    p {
                        margin-top: 0;
                        margin-bottom: 10px;
                    }
                    
                    ul, ol {
                        margin-top: 0;
                        margin-bottom: 10px;
                        padding-left: 20px;
                    }
                    
                    li {
                        margin-bottom: 5px;
                    }
                    
                    code {
                        font-family: Menlo, Monaco, Consolas, monospace;
                        background-color: #f5f5f5;
                        padding: 2px 4px;
                        border-radius: 3px;
                    }
                    
                    pre {
                        background-color: #f5f5f5;
                        padding: 10px;
                        border-radius: 5px;
                        overflow-x: auto;
                    }
                    
                    pre code {
                        padding: 0;
                        background-color: transparent;
                    }
                    
                    blockquote {
                        border-left: 4px solid #ddd;
                        padding-left: 10px;
                        margin-left: 0;
                        color: #666;
                    }
                    
                    a {
                        color: #0366d6;
                        text-decoration: none;
                    }
                    
                    a:hover {
                        text-decoration: underline;
                    }
                    
                    table {
                        border-collapse: collapse;
                        width: 100%;
                        margin-bottom: 10px;
                    }
                    
                    th, td {
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: left;
                    }
                    
                    th {
                        background-color: #f5f5f5;
                    }
                    
                    img {
                        max-width: 100%;
                        height: auto;
                    }
                </style>
            </head>
            <body>
                \(html)
            </body>
            </html>
            """
            
            // HTMLをロード
            webView.loadHTMLString(styledHTML, baseURL: nil)
            
            // スクロール位置を先頭に設定
            webView.scrollView.setContentOffset(.zero, animated: false)
        } catch {
            // Markdownのパースに失敗した場合はプレーンテキストとして表示
            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 18px;
                        line-height: 1.5;
                        margin: 0;
                        padding: 0 10px;
                        color: #000;
                        background-color: transparent;
                    }
                </style>
            </head>
            <body>
                <pre>\(markdown)</pre>
            </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }
}

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
    @State private var inputText = ""
    @State private var isSubmitting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 入力エリアと送信ボタン - コンパクトに
            VStack(spacing: 4) {
                TextEditor(text: $inputText)
                    .frame(minHeight: 60, maxHeight: 100) // 高さをさらに縮小
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .overlay(
                        // プレースホルダーテキスト（入力がない場合のみ表示）
                        Group {
                            if inputText.isEmpty {
                                Text("ジャーナルに追記")
                                    .foregroundColor(Color.gray.opacity(0.7))
                                    .padding(.leading, 20)
                                    .padding(.top, 12)
                            }
                        },
                        alignment: .topLeading
                    )
                
                HStack {
                    Button(action: {
                        submitJournal()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 8) // 縦方向のパディングを小さく
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(inputText.isEmpty || isSubmitting)
                    
                    Button(action: {
                        loadJournal()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("リロード")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 8) // 縦方向のパディングを小さく
                        .padding(.horizontal, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isSubmitting || journal.isLoading)
                }
                .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemBackground))
            
            // ジャーナル表示エリア
            if isSubmitting {
                // 送信中の表示
                VStack {
                    ProgressView("送信中...")
                        .padding()
                    Text("GitHub にジャーナルを送信しています")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else if journal.isLoading {
                // 読み込み中の表示
                VStack {
                    ProgressView("読み込み中...")
                        .padding()
                    Text("GitHub からジャーナルを取得しています")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
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
                // Downライブラリを使用してMarkdownをレンダリング
                GeometryReader { geometry in
                    MarkdownView(markdown: journal.content)
                        .frame(width: geometry.size.width, height: geometry.size.height - 50, alignment: .topLeading) // ボトムナビゲーション用に高さを調整
                        .padding(0) // すべての方向のパディングを0に設定
                        .padding(.bottom, 50) // ボトムナビゲーション用の余白を追加
                        .background(Color.white)
                }
                // SafeAreaを無視するのをやめて、ボトムナビゲーションとの重なりを避ける
            }
        }
        .onAppear {
            loadJournal()
        }
    }
    
    // ジャーナルを送信する
    private func submitJournal() {
        guard !inputText.isEmpty else { return }
        guard settings.isConfigured else {
            journal.error = "設定が完了していません"
            return
        }
        
        isSubmitting = true
        
        // 現在のジャーナル内容を取得し、新しい内容を追加
        let currentContent = journal.content
        let newContent = formatJournalEntry(currentContent: currentContent, newEntry: inputText)
        
        // GitHub APIを使用してファイルを更新
        updateJournalFile(content: newContent)
    }
    
    // 入力されたテキストをフォーマットする
    private func formatJournalEntry(currentContent: String, newEntry: String) -> String {
        let lines = newEntry.split(separator: "\n")
        
        if lines.count == 1 {
            // 1行の場合は "- テキスト" の形式で追加
            return "\(currentContent)\n- \(newEntry)"
        } else {
            // 複数行の場合は "-----" で区切って追加
            return "\(currentContent)\n-----\n\(newEntry)"
        }
    }
    
    // GitHub APIを使用してファイルを更新
    private func updateJournalFile(content: String) {
        let owner = settings.repositoryName.split(separator: "/").first ?? ""
        let repo = settings.repositoryName.split(separator: "/").last ?? ""
        
        guard !owner.isEmpty && !repo.isEmpty else {
            isSubmitting = false
            journal.error = "リポジトリ名の形式が正しくありません。'オーナー名/リポジトリ名'の形式で入力してください。"
            return
        }
        
        let path = getJournalPath()
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            journal.error = "URLの生成に失敗しました"
            return
        }
        
        // まず現在のファイル情報を取得（SHAが必要）
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.addValue("token \(settings.githubPAT)", forHTTPHeaderField: "Authorization")
        getRequest.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: getRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    isSubmitting = false
                    journal.error = "ネットワークエラー: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    isSubmitting = false
                    journal.error = "不明なレスポンス"
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
                        isSubmitting = false
                        journal.error = "JSONの解析エラー: \(error.localizedDescription)"
                    }
                    return
                }
            }
            
            // ファイルの更新または作成
            var putRequest = URLRequest(url: url)
            putRequest.httpMethod = "PUT"
            putRequest.addValue("token \(settings.githubPAT)", forHTTPHeaderField: "Authorization")
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
                    isSubmitting = false
                    journal.error = "リクエストの作成に失敗しました: \(error.localizedDescription)"
                }
                return
            }
            
            // PUTリクエストの送信
            URLSession.shared.dataTask(with: putRequest) { data, response, error in
                DispatchQueue.main.async {
                    // エラー時のみ isSubmitting を false に設定（成功時は5秒後に設定）
                    if let error = error {
                        isSubmitting = false
                        journal.error = "ネットワークエラー: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        isSubmitting = false
                        journal.error = "不明なレスポンス"
                        return
                    }
                    
                    switch httpResponse.statusCode {
                    case 200, 201:
                        // 成功した場合、入力フィールドをクリア
                        inputText = ""
                        
                        // 送信中の状態を維持したまま5秒間待機
                        // isSubmitting はそのままにして、5秒後に自動的にリロード
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            // 5秒後に isSubmitting を false にしてリロード
                            isSubmitting = false
                            loadJournal()
                        }
                        
                    case 401:
                        isSubmitting = false
                        journal.error = "認証エラー: GitHub PATが無効です"
                        
                    case 422:
                        isSubmitting = false
                        journal.error = "不正なリクエスト: ファイルの更新に失敗しました"
                        
                    default:
                        isSubmitting = false
                        journal.error = "APIエラー: ステータスコード \(httpResponse.statusCode)"
                    }
                }
            }.resume()
        }.resume()
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
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "GET"
        request.addValue("token \(settings.githubPAT)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // キャッシュを無効化するヘッダーを追加
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "If-None-Match") // ETAGを無視
        
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
                                
                                // 明示的に新しいインスタンスを作成して状態を更新
                                let updatedJournal = JournalEntry(
                                    content: decodedString,
                                    isLoading: false,
                                    error: nil
                                )
                                journal = updatedJournal
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
