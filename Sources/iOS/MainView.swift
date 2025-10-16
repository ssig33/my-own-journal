import SwiftUI

// メイン画面
struct MainView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingEditView = false
    @State private var showingAddEntryView = false
    
    init() {
        self.viewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())
    }
    
    var body: some View {
        ZStack {
            // コンテンツエリア
            VStack(spacing: 0) {
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

                    // コミット完了の通知
                    if viewModel.showCommitInfo {
                        VStack {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("コミット完了")
                                    .font(.headline)
                                    .foregroundColor(.green)

                                Spacer()

                                Button(action: {
                                    withAnimation {
                                        viewModel.showCommitInfo = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showCommitInfo)
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
            }

            // 右下のFloating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddEntryView = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.9),
                                        Color.blue.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
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
        .sheet(isPresented: $showingAddEntryView) {
            AddJournalEntryView(viewModel: viewModel)
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
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                
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