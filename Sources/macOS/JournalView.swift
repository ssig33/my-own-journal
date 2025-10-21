import SwiftUI
import MarkdownUI

struct JournalView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @State private var showingEditSheet: Bool = false
    @State private var showingAddJournalSheet: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.journal.isLoading {
                    VStack {
                        ProgressView("読み込み中...")
                            .padding()
                        Text("GitHub からジャーナルを取得しています")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.journal.error {
                    VStack(spacing: 16) {
                        Text("エラーが発生しました")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("再読み込み") {
                            viewModel.loadJournal()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        Markdown(viewModel.journal.content)
                            .markdownTextStyle(\.text) {
                                ForegroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 32)
                            .padding(.vertical)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        viewModel.loadJournal()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddJournalSheet = true
                    } label: {
                        Label("追記", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("ジャーナル")
            .onAppear {
                viewModel.loadJournal()
            }
            .sheet(isPresented: $showingEditSheet) {
                EditView(
                    viewModel: EditViewModel(
                        settings: AppSettings.loadFromUserDefaults(),
                        initialContent: viewModel.journal.content
                    ),
                    filePath: viewModel.getJournalPath(),
                    onSave: {
                        viewModel.loadJournal()
                    }
                )
            }
            .sheet(isPresented: $showingAddJournalSheet) {
                AddJournalView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    JournalView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
