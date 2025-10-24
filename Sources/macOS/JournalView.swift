import SwiftUI
import CodeEditor

struct JournalView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var editableContent: String = ""
    @State private var editViewModel: EditViewModel?
    @State private var statusMessage: String = ""
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            CodeEditor(
                source: $editableContent,
                language: .markdown,
                theme: colorScheme == .dark ? .ocean : .atelierSavannaLight
            )
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        loadJournal()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("ジャーナル")
            .navigationSubtitle(statusMessage)
            .onAppear {
                loadJournal()
                editViewModel = EditViewModel(
                    settings: AppSettings.loadFromUserDefaults(),
                    initialContent: viewModel.journal.content
                )
            }
            .onChange(of: viewModel.journal.content) { _, newValue in
                editableContent = newValue
                statusMessage = ""
            }
            .onChange(of: editableContent) { _, _ in
                scheduleAutoSave()
            }
        }
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()

        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                saveContent(isAutoSave: true)
            }
        }
    }

    private func loadJournal() {
        statusMessage = "読み込み中"
        viewModel.loadJournal()
    }

    private func saveContent(isAutoSave: Bool = false) {
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
    JournalView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
