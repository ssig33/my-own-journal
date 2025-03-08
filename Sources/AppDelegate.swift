import SwiftUI
import Foundation

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
                    
                    Text("※ YYYY, MM, DD が含まれている必要があります")
                        .font(.caption)
                        .foregroundColor(.gray)
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
    
    // 設定を保存するメソッド
    private func saveSettings() {
        settings.githubPAT = githubPAT
        settings.repositoryName = repositoryName
        settings.journalRule = journalRule
        
        settings.saveToUserDefaults()
        isSettingsCompleted = settings.isConfigured
    }
}

// メイン画面（仮実装）
struct MainView: View {
    var body: some View {
        Text("メイン画面（実装予定）")
            .font(.largeTitle)
            .padding()
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
