import SwiftUI

@MainActor
class GlobalSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var showingResults: Bool = false

    private let settings: AppSettings
    private let gitHubService: GitHubService

    init(settings: AppSettings) {
        self.settings = settings
        self.gitHubService = GitHubService(settings: settings)
    }

    func search() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            showingResults = false
            return
        }

        isSearching = true
        errorMessage = nil
        showingResults = true

        gitHubService.searchContent(query: searchQuery) { [weak self] results, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error
                self.searchResults = []
            } else {
                self.searchResults = results.filter { $0.type == .file }
                self.errorMessage = nil
            }

            self.isSearching = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        showingResults = false
        errorMessage = nil
    }
}
