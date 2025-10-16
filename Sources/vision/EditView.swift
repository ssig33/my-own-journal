import SwiftUI
import MarkdownUI

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDiscardAlert = false
    @State private var showingConflictAlert = false

    var filePath: String
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isSaving {
                    savingView
                } else if viewModel.conflictDetected {
                    conflictView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if viewModel.showPreview {
                    previewView
                } else {
                    editorView
                }
            }
            .navigationTitle("ファイル編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        if viewModel.hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button(viewModel.showPreview ? "編集" : "プレビュー") {
                        viewModel.togglePreview()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.saveFile(path: filePath) { success in
                            if success {
                                onSave()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasChanges)
                }
            }
            .alert("変更を破棄しますか？", isPresented: $showingDiscardAlert) {
                Button("破棄", role: .destructive) {
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("保存されていない変更は失われます。")
            }
            .sheet(isPresented: $showingConflictAlert) {
                conflictSheetView
            }
            .onAppear {
                viewModel.refreshFileContent(path: filePath)
            }
        }
    }

    // 読み込み中表示
    private var loadingView: some View {
        VStack {
            ProgressView("読み込み中...")
                .padding()
            Text("GitHub からファイルを取得しています")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    // 保存中表示
    private var savingView: some View {
        VStack {
            ProgressView("保存中...")
                .padding()
            Text("GitHub にファイルを保存しています")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // コンフリクト表示
    private var conflictView: some View {
        VStack(spacing: 16) {
            Text("ファイルの編集コンフリクトが検出されました")
                .font(.headline)
                .foregroundColor(.orange)
                .padding(.bottom, 4)

            Text("このファイルは他の場所で編集されています。以下のオプションから選択してください：")
                .font(.body)
                .multilineTextAlignment(.center)

            Button("最新の内容を表示") {
                showingConflictAlert = true
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button("自分の変更を維持") {
                viewModel.keepMyChanges()
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Text("注意: 自分の変更を維持する場合、他の人の変更が上書きされる可能性があります。")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }

    // エラー表示
    private func errorView(_ error: String) -> some View {
        VStack {
            Text("エラーが発生しました")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.bottom, 4)

            Text(error)
                .font(.body)
                .foregroundColor(.red)
                .padding(.bottom)

            Button("再読み込み") {
                viewModel.refreshFileContent(path: filePath)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
    }

    // プレビュー表示
    private var previewView: some View {
        ScrollView {
            Markdown(viewModel.journalContent)
                .markdownTextStyle(\.text) {
                    ForegroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical)
        }
    }

    // エディタ表示
    private var editorView: some View {
        TextEditor(text: $viewModel.journalContent)
            .font(.body)
            .padding(.horizontal)
    }

    // コンフリクトシート
    private var conflictSheetView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("最新の内容")
                    .font(.headline)

                ScrollView {
                    Text(viewModel.latestContent ?? "最新の内容を取得できませんでした")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("コンフリクト")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingConflictAlert = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("最新の内容を採用") {
                        viewModel.acceptLatestContent()
                        showingConflictAlert = false
                    }
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
