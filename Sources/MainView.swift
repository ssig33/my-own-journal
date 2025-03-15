import SwiftUI

// メイン画面
struct MainView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingEditView = false
    @State private var textEditorHeight: CGFloat = 40
    @State private var isExpanded = false
    
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
            
            // 入力エリアと送信ボタン - 洗練されたデザイン
            VStack(spacing: 0) {
                Divider()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 8)
                
                // ZStackを使用して、ボタンの位置を動的に調整
                ZStack(alignment: .topTrailing) {
                    // TextEditor - 常に同じコンポーネントを使用し、高さだけ動的に変更
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: textEditorHeight)
                        // 一行表示時は右側にパディングを追加してボタン用のスペースを確保
                        .padding(.trailing, isExpanded ? 12 : 50)
                        .padding(.leading, 12)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .overlay(
                            // プレースホルダーテキスト（入力がない場合のみ表示）
                            Group {
                                if viewModel.inputText.isEmpty {
                                    Text("ジャーナルに追記")
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(Color.gray.opacity(0.6))
                                        .padding(.leading, 24)
                                        .padding(.top, 20)
                                }
                            },
                            alignment: .topLeading
                        )
                        .onChange(of: viewModel.inputText) { newValue in
                            // テキストの内容に応じて高さと状態を調整
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if newValue.isEmpty {
                                    textEditorHeight = 40
                                    isExpanded = false
                                } else if newValue.contains("\n") || newValue.count > 50 {
                                    textEditorHeight = 120
                                    isExpanded = true
                                }
                            }
                        }
                        .onTapGesture {
                            // タップされたら拡張モードに
                            if !isExpanded && !viewModel.inputText.isEmpty {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    textEditorHeight = 120
                                    isExpanded = true
                                }
                            }
                        }
                        .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                    
                    // 送信ボタン - 浮かせて表示
                    ZStack {
                        // 背景の白い円（テキストとの重なりを防ぐ）
                        if !isExpanded {
                            Circle()
                                .fill(Color(UIColor.systemBackground).opacity(0.9))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        
                        Button(action: {
                            viewModel.submitJournal()
                        }) {
                            HStack(spacing: 4) {
                                if isExpanded {
                                    Text("送信")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: isExpanded ? 14 : 16))
                            }
                            .padding(.vertical, isExpanded ? 10 : 8)
                            .padding(.horizontal, isExpanded ? 16 : 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.9),
                                        Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(isExpanded ? 10 : 20)
                            .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        .disabled(viewModel.inputText.isEmpty || viewModel.isSubmitting)
                    }
                    .scaleEffect(isExpanded ? 1.0 : 0.9)
                    .animation(.spring(response: 0.3), value: isExpanded)
                    // 拡張モードでは下部に、そうでなければ右上に配置
                    .offset(
                        x: isExpanded ? -16 : -24,
                        y: isExpanded ? textEditorHeight - 24 : 20
                    )
                    .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(.bottom, isExpanded ? 40 : 8)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.systemBackground).opacity(0.98)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: -2)
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