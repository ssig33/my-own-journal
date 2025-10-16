import SwiftUI
import MarkdownUI

struct FileViewWindowView: View {
    let filePath: String
    @State private var content: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @Environment(\.openWindow) private var openWindow

    private let githubService: GitHubService

    init(filePath: String) {
        self.filePath = filePath
        self.githubService = GitHubService(settings: AppSettings.loadFromUserDefaults())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("再読み込み") {
                        loadContent()
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button("検索") {
                        openWindow(id: "search")
                    }
                }
            }
            .navigationTitle(fileName)
            .onAppear {
                loadContent()
            }
        }
    }

    private var fileName: String {
        filePath.split(separator: "/").last.map(String.init) ?? "Unknown"
    }

    private var contentView: some View {
        ScrollView {
            Markdown(content)
                .markdownTextStyle(\.text) {
                    ForegroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical)
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("読み込み中...")
                .padding()
            Text("GitHub からデータを取得しています")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private func errorView(_ error: String) -> some View {
        VStack {
            Text("エラーが発生しました")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.bottom, 4)

            Text(error)
                .font(.body)
                .foregroundColor(.red)
        }
        .padding()
    }

    private func loadContent() {
        isLoading = true
        errorMessage = nil

        githubService.getFileContent(path: filePath) { [self] fetchedContent, error in
            isLoading = false

            if let error = error {
                errorMessage = error
            } else if let fetchedContent = fetchedContent {
                content = fetchedContent
            } else {
                errorMessage = "ファイルの内容を読み込めませんでした"
            }
        }
    }
}

#Preview {
    FileViewWindowView(filePath: "example/test.md")
}
