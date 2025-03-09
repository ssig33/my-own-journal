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
                
                Section {
                    Button("保存") {
                        viewModel.saveSettings()
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView(
        settings: .constant(AppSettings.defaultSettings),
        isSettingsCompleted: .constant(false)
    )
}