import SwiftUI
import CoreSpotlight

@main
struct MyOwnJournalApp: App {
    var body: some Scene {
        Window("ジャーナル", id: "main-window") {
            MainWindowView()
        }

        Window("設定", id: "settings") {
            SettingsWindowView()
        }
    }
}
