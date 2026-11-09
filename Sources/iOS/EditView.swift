import SwiftUI

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var editableContent: String = ""
    @State private var statusMessage: String = ""
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var isSaving: Bool = false

    var filePath: String
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MyEditor(source: $editableContent)
                    .onChange(of: editableContent) { _, _ in
                        scheduleAutoSave()
                    }
            }
            .navigationBarTitle("ファイル編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("閉じる") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        loadContent()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }
            )
            .onAppear {
                loadContent()
            }
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

    private func loadContent() {
        statusMessage = "読み込み中"
        viewModel.refreshFileContent(path: filePath) { success in
            if success {
                editableContent = viewModel.journalContent
            }
            statusMessage = viewModel.error.map { "読み込み失敗: \($0)" } ?? ""
        }
    }

    private func saveContent() {
        guard !isSaving else { return }

        viewModel.journalContent = editableContent
        // 読み込んだだけ、または保存済みの内容と同じなら保存しない
        guard viewModel.hasChanges else { return }

        isSaving = true
        statusMessage = "保存中"
        viewModel.saveFile(path: filePath) { success in
            isSaving = false
            statusMessage = SaveStatus.message(success: success, error: viewModel.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + SaveStatus.displayDuration) {
                statusMessage = ""
            }
        }
    }
}

#Preview {
    EditView(
        viewModel: EditViewModel(
            settings: AppSettings.loadFromUserDefaults(),
            initialContent: "# サンプルジャーナル\n\nこれはプレビューです。"
        ),
        filePath: "sample.md",
        onSave: {}
    )
}
