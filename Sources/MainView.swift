import SwiftUI

// メイン画面
struct MainView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingEditView = false
    
    init() {
        self.viewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // コンテンツエリア
            ZStack {
                // ジャーナル表示
                if !viewModel.isSubmitting && !viewModel.journal.isLoading && viewModel.journal.error == nil {
                    journalContentView
                }
                
                // 送信中の表示
                if viewModel.isSubmitting {
                    VStack {
                        ProgressView("送信中...")
                            .padding()
                        Text("GitHub にジャーナルを送信しています")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 読み込み中の表示
                if viewModel.journal.isLoading {
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
                }
                
                // エラー表示
                if let error = viewModel.journal.error {
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
                }
            }
            
            // 入力エリアと送信ボタン - コンパクトに
            VStack(spacing: 4) {
                Divider()
                
                TextEditor(text: $viewModel.inputText)
                    .frame(minHeight: 60, maxHeight: 100) // 高さをさらに縮小
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .overlay(
                        // プレースホルダーテキスト（入力がない場合のみ表示）
                        Group {
                            if viewModel.inputText.isEmpty {
                                Text("ジャーナルに追記")
                                    .foregroundColor(Color.gray.opacity(0.7))
                                    .padding(.leading, 20)
                                    .padding(.top, 12)
                            }
                        },
                        alignment: .topLeading
                    )
                    .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                
                HStack {
                    Button(action: {
                        viewModel.submitJournal()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 8) // 縦方向のパディングを小さく
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isSubmitting)
                    
                    Button(action: {
                        viewModel.loadJournal()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("リロード")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 8) // 縦方向のパディングを小さく
                        .padding(.horizontal, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isSubmitting || viewModel.journal.isLoading)
                }
                .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            viewModel.loadJournal()
        }
        .sheet(isPresented: $showingEditView) {
            EditView(
                viewModel: EditViewModel(
                    settings: AppSettings.loadFromUserDefaults(),
                    initialContent: viewModel.journal.content
                ),
                filePath: viewModel.getJournalPath(), // 現在のジャーナルのパスを指定
                onSave: {
                    // 編集が保存されたらジャーナルを再読み込み
                    viewModel.loadJournal()
                }
            )
        }
    }
    
    // ジャーナル内容表示
    private var journalContentView: some View {
        VStack(spacing: 0) {
            // ファイル名ヘッダー
            HStack {
                Text("ジャーナル")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // リロードボタン
                Button(action: {
                    viewModel.loadJournal()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 4)
                
                // 編集ボタン
                Button(action: {
                    showingEditView = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // ジャーナル内容
            GeometryReader { geometry in
                MarkdownView(markdown: viewModel.journal.content)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                    .padding(0)
                    .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
            }
        }
    }
}

#Preview {
    MainView()
}