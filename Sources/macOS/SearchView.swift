import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.openWindow) private var openWindow
    let filePath: String?

    init(filePath: String? = nil) {
        self.filePath = filePath
        self.viewModel = SearchViewModel(settings: AppSettings.loadFromUserDefaults())
        self.viewModel.search()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    if viewModel.showingResults {
                        resultListView
                    }

                    if !viewModel.showingResults {
                        emptyStateView
                    }

                    if viewModel.isSearching {
                        loadingView
                    }
                }

                searchFormView
            }
            .navigationTitle("検索")
            .onAppear {
                if let path = filePath {
                    openWindow(value: path)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingNewFileForm) {
            newFileFormView
        }
    }

    private var searchFormView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                TextField("検索", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.search()
                    }

                Button("検索") {
                    viewModel.search()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

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

    private var resultListView: some View {
        List {
            if !viewModel.currentPath.isEmpty {
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
                        if result.type == .directory {
                            viewModel.selectFile(result)
                        } else {
                            openWindow(value: result.path)
                        }
                    }) {
                        HStack {
                            Image(systemName: result.type == .directory ? "folder" : "doc.text")
                                .foregroundColor(result.type == .directory ? .blue : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name)
                                    .foregroundColor(.primary)

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
        .listStyle(.inset)
    }

    private var loadingView: some View {
        VStack {
            ProgressView("読み込み中...")
                .padding()
            Text("GitHub からデータを取得しています")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var newFileFormView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("新規ファイル作成")
                    .font(.headline)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ファイルパス")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    TextField("ファイルパス", text: $viewModel.newFileName)
                        .textFieldStyle(.roundedBorder)
                        .padding()

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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.cancelNewFileForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        viewModel.createNewFile { _ in
                        }
                    }
                    .disabled(viewModel.newFileName.isEmpty || viewModel.isCreatingFile)
                }
            }
            .navigationTitle("新規ファイル")
            .frame(minWidth: 400, minHeight: 300)
        }
    }
}

#Preview {
    SearchView()
}
