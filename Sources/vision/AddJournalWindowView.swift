import SwiftUI

struct AddJournalWindowView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding()

                if viewModel.isSubmitting {
                    HStack {
                        ProgressView()
                        Text("送信中...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                if let error = viewModel.journal.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding()
                }
            }
            .navigationTitle("ジャーナル追記")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        viewModel.submitJournal()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !viewModel.isSubmitting && viewModel.journal.error == nil {
                                dismiss()
                                openWindow(id: "main-window")
                            }
                        }
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isSubmitting)
                }
            }
            .onChange(of: viewModel.showCommitInfo) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AddJournalWindowView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
