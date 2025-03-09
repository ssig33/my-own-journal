import SwiftUI
import CoreSpotlight

struct ContentView: View {
    @State private var settings = AppSettings.loadFromUserDefaults()
    @State private var isSettingsCompleted = AppSettings.loadFromUserDefaults().isConfigured
    @State private var selectedTab: Int
    @State private var spotlightFilePath: String?
    
    init() {
        // 初期状態で設定が完了していなければ、設定タブ（tag 1）を初期選択にする
        let configured = AppSettings.loadFromUserDefaults().isConfigured
        _selectedTab = State(initialValue: configured ? 0 : 1)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // メインタブ（設定完了かどうかで表示を切り替え）
            Group {
                if isSettingsCompleted {
                    MainView()
                } else {
                    VStack {
                        Spacer()
                        Text("設定を完了してください")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("リロード") {
                            settings = AppSettings.loadFromUserDefaults()
                            isSettingsCompleted = settings.isConfigured
                        }
                        Spacer()
                    }
                }
            }
            .tabItem {
                Label("ジャーナル", systemImage: "book.fill")
            }
            .tag(0)
            
            // 検索閲覧タブ（設定完了かどうかで表示を切り替え）
            Group {
                if isSettingsCompleted {
                    SearchView(filePath: spotlightFilePath)
                } else {
                    VStack {
                        Spacer()
                        Text("設定を完了してください")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("リロード") {
                            settings = AppSettings.loadFromUserDefaults()
                            isSettingsCompleted = settings.isConfigured
                        }
                        Spacer()
                    }
                }
            }
            .tabItem {
                Label("検索", systemImage: "magnifyingglass")
            }
            .tag(2)
            
            // 設定タブは常に利用可能
            SettingsView(settings: $settings, isSettingsCompleted: $isSettingsCompleted)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(1)
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            // Spotlight検索結果からの遷移を処理
            if let path = SpotlightService.getPathFromSpotlightUserActivity(userActivity) {
                spotlightFilePath = path
                selectedTab = 2 // 検索タブに切り替え
            }
        }
    }
}

#Preview {
    ContentView()
}
