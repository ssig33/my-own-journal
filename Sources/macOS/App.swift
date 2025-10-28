import SwiftUI
import CoreSpotlight

@main
struct MyOwnJournalApp: App {
    @StateObject private var journalViewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())

    var body: some Scene {
        Window("Journal", id: "main-window") {
            ContentView()
                .environmentObject(journalViewModel)
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("検索") {
                    NotificationCenter.default.post(name: NSNotification.Name("FocusGlobalSearch"), object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }

        WindowGroup(for: String.self) { $filePath in
            if let filePath = filePath {
                FileViewWindowView(filePath: filePath)
            }
        }
    }
}
