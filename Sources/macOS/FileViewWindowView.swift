import SwiftUI
import CodeEditor
import os.log

struct FileViewWindowView: View {
    private let logger = Logger(subsystem: "com.ssig33.MyOwnJournal", category: "FileViewWindowView")
    let filePath: String
    @State private var editableContent: String = ""
    @State private var editViewModel: EditViewModel?
    @State private var statusMessage: String = ""
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var isSaving: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private let githubService: GitHubService

    init(filePath: String) {
        self.filePath = filePath
        self.githubService = GitHubService(settings: AppSettings.loadFromUserDefaults())
    }

    var body: some View {
        NavigationStack {
            CodeEditor(
                source: $editableContent,
                language: .markdown,
                theme: colorScheme == .dark ? .ocean : .atomOneLight
            )
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        loadContent()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle(fileName)
            .navigationSubtitle(statusMessage)
            .onAppear {
                loadContent()
                editViewModel = EditViewModel(
                    settings: AppSettings.loadFromUserDefaults(),
                    initialContent: ""
                )
            }
            .onChange(of: editableContent) { _, _ in
                scheduleAutoSave()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var fileName: String {
        filePath.split(separator: "/").last.map(String.init) ?? "Unknown"
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()

        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                saveContent()
            }
        }
    }

    private func loadContent() {
        logger.info("loadContent() called for path: \(self.filePath)")
        statusMessage = "読み込み中"

        githubService.getFileContent(path: filePath) { fetchedContent, error in
            DispatchQueue.main.async {
                self.logger.info("getFileContent callback received")

                if let error = error {
                    self.logger.error("Error loading content: \(error)")
                    self.statusMessage = "読み込み失敗: \(error)"
                } else if let fetchedContent = fetchedContent {
                    self.logger.info("Content loaded successfully, length: \(fetchedContent.count)")
                    self.editableContent = fetchedContent
                    self.statusMessage = ""
                } else {
                    self.logger.warning("No content and no error received")
                    self.statusMessage = "ファイルの内容を読み込めませんでした"
                }
            }
        }
    }

    private func saveContent() {
        guard let editViewModel = editViewModel else { return }
        guard !isSaving else { return }

        isSaving = true
        statusMessage = "保存中"
        editViewModel.journalContent = editableContent
        editViewModel.saveFile(path: filePath) { success in
            isSaving = false
            if success {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                statusMessage = "保存完了: \(formatter.string(from: Date()))"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    statusMessage = ""
                }
            } else {
                if let error = editViewModel.error {
                    statusMessage = "保存失敗: \(error)"
                } else {
                    statusMessage = "保存失敗"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    statusMessage = ""
                }
            }
        }
    }
}

#Preview {
    FileViewWindowView(filePath: "example/test.md")
}
