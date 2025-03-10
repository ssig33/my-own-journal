import SwiftUI

// 設定画面
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    init(settings: Binding<AppSettings>, isSettingsCompleted: Binding<Bool>) {
        self.viewModel = SettingsViewModel(
            settings: settings.wrappedValue,
            isSettingsCompleted: isSettingsCompleted.wrappedValue
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub設定")) {
                    TextField("GitHub Personal Access Token", text: $viewModel.githubPAT)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("リポジトリ名", text: $viewModel.repositoryName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                Section(header: Text("ジャーナル設定")) {
                    TextField("ジャーナルの記録ルール", text: $viewModel.journalRule)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
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
                .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                
                Section(header: Text("Spotlight検索")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let lastUpdate = viewModel.settings.lastSpotlightIndexUpdate {
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
                .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
                
                Section {
                    Button("保存") {
                        viewModel.saveSettings()
                    }
                    .disabled(!viewModel.isFormValid)
                }
                .dismissKeyboardOnTap() // キーボードを閉じる機能を追加
            }
            .navigationTitle("設定")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    SettingsView(
        settings: .constant(AppSettings.defaultSettings),
        isSettingsCompleted: .constant(false)
    )
}