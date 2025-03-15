import SwiftUI

// 検索閲覧画面
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    init(filePath: String? = nil) {
        self.viewModel = SearchViewModel(settings: AppSettings.loadFromUserDefaults())
        
        // 特定のファイルパスが指定されている場合はそのファイルを表示
        if let path = filePath {
            self.viewModel.openFileByPath(path)
        } else {
            // 初期表示時にルートディレクトリの内容を表示
            self.viewModel.search()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // コンテンツエリア
            ZStack {
                // 検索結果表示
                if viewModel.showingResults {
                    resultListView
                        .opacity(viewModel.showingFileContent ? 0 : 1)
                        .animation(.easeInOut, value: viewModel.showingFileContent)
                        .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                }
                
                // ファイル内容表示
                if viewModel.showingFileContent, let selectedFile = viewModel.selectedFile {
                    fileContentView(selectedFile)
                        .opacity(viewModel.showingFileContent ? 1 : 0)
                        .animation(.easeInOut, value: viewModel.showingFileContent)
                        .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                }
                
                // 初期状態（emptystate）
                if !viewModel.showingResults && !viewModel.showingFileContent {
                    emptyStateView
                        .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                }
                
                // 読み込み中
                if viewModel.isSearching {
                    loadingView
                }
            }
            
            // 検索フォーム（ボトムナビの上に固定）
            searchFormView
        }
        .sheet(isPresented: $viewModel.showingEditView) {
            if let selectedFile = viewModel.selectedFile, let content = selectedFile.content {
                EditView(
                    viewModel: EditViewModel(
                        settings: AppSettings.loadFromUserDefaults(),
                        initialContent: content
                    ),
                    filePath: selectedFile.path, // 編集対象ファイルのパスを明示的に指定
                    onSave: { [weak viewModel] in
                        // 編集が保存されたらファイル内容を再読み込み
                        if let viewModel = viewModel, let selectedFile = viewModel.selectedFile {
                            viewModel.selectFile(selectedFile)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingNewFileForm) {
            newFileFormView
        }
    }
    
    // 検索フォーム
    private var searchFormView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                TextField("検索", text: $viewModel.searchQuery)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button(action: {
                    viewModel.search()
                }) {
                    Text("検索")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // 初期状態（emptystate）
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding()
            
            Text("検索してファイルを表示")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("検索フォームにキーワードを入力して検索ボタンを押してください")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    // 検索結果リスト
    private var resultListView: some View {
        List {
            if !viewModel.currentPath.isEmpty {
                // 親ディレクトリに戻るボタン
                Button(action: {
                    viewModel.navigateToParentDirectory()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                        
                        Text("上の階層へ")
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 新規ファイル作成ボタン
            Button(action: {
                viewModel.showNewFileForm()
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(.green)
                    
                    Text("新規ファイル作成")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.searchResults.isEmpty {
                Text("検索結果がありません")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.searchResults) { result in
                    Button(action: {
                        viewModel.selectFile(result)
                    }) {
                        HStack {
                            Image(systemName: result.type == .directory ? "folder" : "doc.text")
                                .foregroundColor(result.type == .directory ? .blue : .gray)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name)
                                    .foregroundColor(.primary)
                                
                                // 検索クエリが入力されている場合のみパスを表示
                                if !viewModel.searchQuery.isEmpty {
                                    Text(result.path)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if result.type == .directory {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // ファイル内容表示
    private func fileContentView(_ file: SearchResult) -> some View {
        VStack(spacing: 0) {
            // ファイル名ヘッダー
            HStack {
                Button(action: {
                    viewModel.backToResults()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // リロードボタン
                Button(action: {
                    if let selectedFile = viewModel.selectedFile {
                        viewModel.selectFile(selectedFile)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 4)
                
                // 編集ボタン（Markdownファイルのみ）
                if file.name.hasSuffix(".md") {
                    Button(action: {
                        viewModel.showingEditView = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // ファイル内容
            if let error = file.error {
                VStack {
                    Text("エラーが発生しました")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.bottom, 4)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                }
                .padding()
            } else if let content = file.content {
                // Markdownをレンダリング
                GeometryReader { geometry in
                    MarkdownView(markdown: content)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                        .padding(0)
                }
            } else {
                Text("ファイルの内容を読み込めませんでした")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    // 読み込み中表示
    private var loadingView: some View {
        VStack {
            ProgressView("読み込み中...")
                .padding()
            Text("GitHub からデータを取得しています")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    // 新規ファイル作成フォーム
    private var newFileFormView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("新規ファイル作成")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ファイルパス")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("ファイルパス", text: $viewModel.newFileName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("※ .md拡張子は自動的に追加されます")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("※ パスが / で終わる場合は index.md が追加されます")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                if viewModel.isCreatingFile {
                    ProgressView("ファイル作成中...")
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button("キャンセル") {
                    viewModel.cancelNewFileForm()
                },
                trailing: Button("作成") {
                    viewModel.createNewFile { _ in
                        // 成功時はViewModelで処理
                    }
                }
                .disabled(viewModel.newFileName.isEmpty || viewModel.isCreatingFile)
            )
            .dismissKeyboardOnTap()
        }
    }
}

#Preview {
    SearchView()
}