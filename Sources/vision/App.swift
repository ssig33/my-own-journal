import SwiftUI
import CoreSpotlight

@main
struct MyOwnJournalApp: App {
    @StateObject private var journalViewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())

    var body: some Scene {
        Window("ジャーナル", id: "main-window") {
            MainWindowView()
                .environmentObject(journalViewModel)
        }

        Window("設定", id: "settings") {
            SettingsWindowView()
        }

        Window("検索", id: "search") {
            SearchWindowView()
        }

        WindowGroup(for: String.self) { $filePath in
            if let filePath = filePath {
                FileViewWindowView(filePath: filePath)
            }
        }

        Window("ジャーナル追記", id: "add-journal") {
            AddJournalWindowView()
                .environmentObject(journalViewModel)
        }
        .defaultSize(width: 500, height: 400)
    }
}
