import SwiftUI
import CoreSpotlight

enum NavigationItem: String, CaseIterable {
    case journal = "ジャーナル"
    case search = "検索"
    case settings = "設定"

    var icon: String {
        switch self {
        case .journal: return "book.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var selectedItem: NavigationItem = .journal
    @State private var settings = AppSettings.loadFromUserDefaults()
    @State private var isSettingsCompleted = AppSettings.loadFromUserDefaults().isConfigured
    @State private var spotlightFilePath: String?

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, id: \.self, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
            .listStyle(.sidebar)
        } detail: {
            if isSettingsCompleted || selectedItem == .settings {
                detailView
            } else {
                settingsRequiredView
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let path = SpotlightService.getPathFromSpotlightUserActivity(userActivity) {
                spotlightFilePath = path
                selectedItem = .search
            }
        }
        .onChange(of: settings.isConfigured) { _, newValue in
            isSettingsCompleted = newValue
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .journal:
            JournalView()
                .environmentObject(journalViewModel)
        case .search:
            SearchView(filePath: spotlightFilePath)
        case .settings:
            SettingsView(settings: $settings, isSettingsCompleted: $isSettingsCompleted)
        }
    }

    private var settingsRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("設定を完了してください")
                .font(.headline)
                .foregroundColor(.secondary)

            Button("設定画面へ") {
                selectedItem = .settings
            }
            .buttonStyle(.borderedProminent)

            Button("リロード") {
                settings = AppSettings.loadFromUserDefaults()
                isSettingsCompleted = settings.isConfigured
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
