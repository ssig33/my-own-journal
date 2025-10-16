import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.openWindow) private var openWindow

    init() {
        let settings = AppSettings.loadFromUserDefaults()
        self.viewModel = SettingsViewModel(
            settings: settings,
            isSettingsCompleted: settings.isConfigured
        )
    }

    var body: some View {
        NavigationStack {
            Form {
            Section(header: Text("GitHub設定")) {
                TextField("GitHub Personal Access Token", text: $viewModel.githubPAT)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("リポジトリ名", text: $viewModel.repositoryName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section(header: Text("ジャーナル設定")) {
                TextField("ジャーナルの記録ルール", text: $viewModel.journalRule)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text("例: log/YYYY/MM/DD.md")
                    .font(.caption)
                    .foregroundColor(.gray)

                if !viewModel.isJournalRuleValid && !viewModel.journalRule.isEmpty {
                    Text("※ YYYY, MM, DD が含まれている必要があります")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("※ YYYY, MM, DD が含まれている必要があります")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if !viewModel.journalRule.isEmpty && viewModel.isJournalRuleValid {
                    Text("今日の場合：\(viewModel.expandJournalRule(viewModel.journalRule))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Section(header: Text("Spotlight検索")) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.settings.lastSpotlightIndexUpdate != nil {
                        Text("最終更新: \(viewModel.settings.getLastSpotlightUpdateFormatted())")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("インデックス登録ファイル数: \(viewModel.indexedFilesCount)件")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("インデックスは未作成です")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        viewModel.updateSpotlightIndex()
                    }) {
                        HStack {
                            Text("検索インデックスを更新")
                            Spacer()
                            if viewModel.isUpdatingSpotlightIndex {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(viewModel.isUpdatingSpotlightIndex || !viewModel.settings.isConfigured)

                    if viewModel.spotlightIndexSuccess {
                        Text("インデックスの更新が完了しました（\(viewModel.indexedFilesCount)件のファイルを登録）")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if let error = viewModel.spotlightIndexError {
                        Text("エラー: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Button("保存") {
                    viewModel.saveSettings()
                }
                .disabled(!viewModel.isFormValid)
            }
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("ジャーナル") {
                        openWindow(id: "main-window")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsWindowView()
}
