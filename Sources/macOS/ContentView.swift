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
    @StateObject private var globalSearchViewModel: GlobalSearchViewModel
    @FocusState private var searchFieldFocused: Bool
    @Environment(\.openWindow) private var openWindow

    init() {
        let settings = AppSettings.loadFromUserDefaults()
        _globalSearchViewModel = StateObject(wrappedValue: GlobalSearchViewModel(settings: settings))
    }

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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                globalSearchBox
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusGlobalSearch"))) { _ in
            searchFieldFocused = true
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

    private var globalSearchBox: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("検索", text: $globalSearchViewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
                    .focused($searchFieldFocused)
                    .onSubmit {
                        print("DEBUG: onSubmit called")
                        globalSearchViewModel.search()
                    }
                    .onChange(of: globalSearchViewModel.searchQuery) { oldValue, newValue in
                        print("DEBUG: searchQuery changed from '\(oldValue)' to '\(newValue)'")
                    }
                    .onChange(of: searchFieldFocused) { oldValue, newValue in
                        print("DEBUG: searchFieldFocused changed from \(oldValue) to \(newValue)")
                    }

                if globalSearchViewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if !globalSearchViewModel.searchQuery.isEmpty {
                    Button(action: {
                        globalSearchViewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $globalSearchViewModel.showingResults) {
                        searchResultsPopover
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
    }

    private var searchResultsPopover: some View {
        VStack(spacing: 0) {
            if let errorMessage = globalSearchViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(width: 400)
            } else if globalSearchViewModel.searchResults.isEmpty && !globalSearchViewModel.isSearching {
                Text("検索結果がありません")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(width: 400)
            } else {
                List(globalSearchViewModel.searchResults) { result in
                    Button(action: {
                        openWindow(value: result.path)
                        globalSearchViewModel.clearSearch()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name)
                                    .foregroundColor(.primary)

                                Text(result.path)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 400, height: min(CGFloat(globalSearchViewModel.searchResults.count) * 44 + 20, 400))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
