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

        WindowGroup(for: String.self) { $filePath in
            if let filePath = filePath {
                FileViewWindowView(filePath: filePath)
            }
        }
    }
}
