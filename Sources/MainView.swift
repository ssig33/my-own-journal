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
            // ジャーナル表示エリア
            if viewModel.isSubmitting {
                // 送信中の表示
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
            } else if viewModel.journal.isLoading {
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
            } else if let error = viewModel.journal.error {
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
            } else {
                // Downライブラリを使用してMarkdownをレンダリング
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geometry in
                        MarkdownView(markdown: viewModel.journal.content)
                            .frame(width: geometry.size.width, height: geometry.size.height - 50, alignment: .topLeading) // ボトムナビゲーション用に高さを調整
                            .padding(0) // すべての方向のパディングを0に設定
                            .padding(.bottom, 50) // ボトムナビゲーション用の余白を追加
                            .background(Color.white)
                    }
                    
                    // 編集ボタン
                    Button(action: {
                        showingEditView = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .padding(16)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
                // SafeAreaを無視するのをやめて、ボトムナビゲーションとの重なりを避ける
            }
            // 入力エリアと送信ボタン - コンパクトに
            VStack(spacing: 4) {
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
}

#Preview {
    MainView()
}