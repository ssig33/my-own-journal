import SwiftUI
import CoreSpotlight

@main
struct MyOwnJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // アプリ起動時にSpotlightの検索可能性を確保
                    CSSearchableIndex.default().deleteAllSearchableItems { error in
                        if let error = error {
                            print("Spotlight初期化エラー: \(error.localizedDescription)")
                        }
                    }
                }
        }
        .handlesExternalEvents(matching: [CSSearchableItemActionType])
    }
}
