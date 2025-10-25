import SwiftUI

// メイン画面
struct MainView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var editableContent: String = ""
    @State private var editViewModel: EditViewModel?
    @State private var statusMessage: String = ""
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var isSaving: Bool = false
    @FocusState private var isEditorFocused: Bool

    init() {
        self.viewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())
    }

    var body: some View {
        ZStack {
            // コンテンツエリア
            VStack(spacing: 0) {
                // ツールバー
                HStack {
                    Text("ジャーナル")
                        .font(.headline)

                    Spacer()

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        loadJournal()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .onTapGesture {
                    isEditorFocused = false
                }

                Divider()

                // Editor
                MyEditor(source: $editableContent)
                    .focused($isEditorFocused)
                    .onChange(of: editableContent) { _, _ in
                        scheduleAutoSave()
                    }
                    .onChange(of: viewModel.journal.content) { oldValue, newValue in
                        print("[MainView] onChange(journal.content): oldLength=\(oldValue.count) newLength=\(newValue.count)")
                        editableContent = newValue
                    }
                    .onChange(of: viewModel.journal.isLoading) { oldValue, newValue in
                        print("[MainView] onChange(journal.isLoading): old=\(oldValue) new=\(newValue)")
                        if !newValue {
                            // 読み込み完了時
                            if let error = viewModel.journal.error {
                                statusMessage = "読み込み失敗: \(error)"
                            } else {
                                statusMessage = ""
                            }
                        }
                    }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            loadJournal()
            editViewModel = EditViewModel(
                settings: AppSettings.loadFromUserDefaults(),
                initialContent: viewModel.journal.content
            )
        }
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

    private func loadJournal() {
        print("[MainView] loadJournal: 呼び出された")
        statusMessage = "読み込み中"
        viewModel.loadJournal()
    }

    private func saveContent() {
        guard let editViewModel = editViewModel else { return }
        guard !isSaving else { return }

        isSaving = true
        statusMessage = "保存中"
        editViewModel.journalContent = editableContent
        editViewModel.saveFile(path: viewModel.getJournalPath()) { success in
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
    MainView()
}
