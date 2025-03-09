import SwiftUI

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