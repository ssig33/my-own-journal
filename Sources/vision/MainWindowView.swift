import SwiftUI
import MarkdownUI

struct MainWindowView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @Environment(\.openWindow) private var openWindow

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
                        Image(systemName: "arrow.clockwise")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        openWindow(id: "add-journal")
                    } label: {
                        Label("追記", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button("検索") {
                        openWindow(id: "search")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button("設定") {
                        openWindow(id: "settings")
                    }
                }
            }
            .navigationTitle("ジャーナル")
            .onAppear {
                viewModel.loadJournal()
            }
        }
    }
}

#Preview {
    MainWindowView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
