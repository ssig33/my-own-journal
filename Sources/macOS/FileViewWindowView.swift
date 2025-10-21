import SwiftUI
import MarkdownUI
import os.log

struct FileViewWindowView: View {
    private let logger = Logger(subsystem: "com.ssig33.MyOwnJournal", category: "FileViewWindowView")
    let filePath: String
    @State private var content: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showingEditSheet: Bool = false

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
                        logger.info("Reload button tapped")
                        loadContent()
                    }
                }

                if fileName.hasSuffix(".md") {
                    ToolbarItem(placement: .automatic) {
                        Button("編集") {
                            showingEditSheet = true
                        }
                    }
                }
            }
            .navigationTitle(fileName)
            .onAppear {
                loadContent()
            }
            .sheet(isPresented: $showingEditSheet) {
                EditView(
                    viewModel: EditViewModel(
                        settings: AppSettings.loadFromUserDefaults(),
                        initialContent: content
                    ),
                    filePath: filePath,
                    onSave: {
                        logger.info("onSave callback called, reloading content")
                        loadContent()
                    }
                )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
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
        logger.info("loadContent() called for path: \(self.filePath)")
        isLoading = true
        errorMessage = nil

        githubService.getFileContent(path: filePath) { fetchedContent, error in
            DispatchQueue.main.async {
                self.logger.info("getFileContent callback received")
                self.isLoading = false

                if let error = error {
                    self.logger.error("Error loading content: \(error)")
                    self.errorMessage = error
                } else if let fetchedContent = fetchedContent {
                    self.logger.info("Content loaded successfully, length: \(fetchedContent.count)")
                    self.content = fetchedContent
                } else {
                    self.logger.warning("No content and no error received")
                    self.errorMessage = "ファイルの内容を読み込めませんでした"
                }
            }
        }
    }
}

#Preview {
    FileViewWindowView(filePath: "example/test.md")
}
