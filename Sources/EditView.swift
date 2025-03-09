import SwiftUI

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDiscardAlert = false
    @State private var showingConflictAlert = false
    
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
                        Text("GitHub からファイルを取得しています")
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
                        Text("GitHub にファイルを保存しています")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else if viewModel.conflictDetected {
                    // コンフリクト検出時の表示
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
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("自分の変更を維持") {
                            viewModel.keepMyChanges()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Text("注意: 自分の変更を維持する場合、他の人の変更が上書きされる可能性があります。")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
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
                            viewModel.refreshFileContent(path: filePath)
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
            .navigationBarTitle("ファイル編集", displayMode: .inline)
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
            .sheet(isPresented: $showingConflictAlert) {
                VStack(spacing: 20) {
                    Text("最新の内容")
                        .font(.headline)
                    
                    ScrollView {
                        Text(viewModel.latestContent ?? "最新の内容を取得できませんでした")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    HStack {
                        Button("キャンセル") {
                            showingConflictAlert = false
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button("最新の内容を採用") {
                            viewModel.acceptLatestContent()
                            showingConflictAlert = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .onAppear {
                // ビュー表示時に最新のファイル内容とSHAを取得
                viewModel.refreshFileContent(path: filePath)
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