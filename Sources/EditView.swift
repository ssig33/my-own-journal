import SwiftUI

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDiscardAlert = false
    
    var filePath: String
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    // 読み込み中の表示
                    VStack {
                        ProgressView("読み込み中...")
                            .padding()
                        Text("GitHub からジャーナルを取得しています")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else if viewModel.isSaving {
                    // 保存中の表示
                    VStack {
                        ProgressView("保存中...")
                            .padding()
                        Text("GitHub にジャーナルを保存しています")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else if let error = viewModel.error {
                    // エラー表示
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
                            viewModel.loadJournal()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if viewModel.showPreview {
                    // プレビュー表示
                    VStack {
                        MarkdownView(markdown: viewModel.journalContent)
                            .padding(.horizontal)
                    }
                } else {
                    // 編集表示
                    VStack {
                        TextEditor(text: $viewModel.journalContent)
                            .font(.body)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitle("ジャーナル編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    if viewModel.hasChanges {
                        showingDiscardAlert = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                trailing: HStack {
                    Button(viewModel.showPreview ? "編集" : "プレビュー") {
                        viewModel.togglePreview()
                    }
                    
                    Button("保存") {
                        // 指定されたパスのファイルを保存
                        viewModel.saveFile(path: filePath) { success in
                            if success {
                                onSave()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasChanges)
                }
            )
            .alert(isPresented: $showingDiscardAlert) {
                Alert(
                    title: Text("変更を破棄しますか？"),
                    message: Text("保存されていない変更は失われます。"),
                    primaryButton: .destructive(Text("破棄")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
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