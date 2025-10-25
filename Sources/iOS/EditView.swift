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
        viewModel.refreshFileContent(path: filePath)

        // ViewModelから内容を取得
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            editableContent = viewModel.journalContent
            statusMessage = ""
        }
    }

    private func saveContent() {
        guard !isSaving else { return }

        isSaving = true
        statusMessage = "保存中"
        viewModel.journalContent = editableContent
        viewModel.saveFile(path: filePath) { success in
            isSaving = false
            if success {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                statusMessage = "保存完了: \(formatter.string(from: Date()))"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    statusMessage = ""
                }
            } else {
                if let error = viewModel.error {
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
    EditView(
        viewModel: EditViewModel(
            settings: AppSettings.loadFromUserDefaults(),
            initialContent: "# サンプルジャーナル\n\nこれはプレビューです。"
        ),
        filePath: "sample.md",
        onSave: {}
    )
}
