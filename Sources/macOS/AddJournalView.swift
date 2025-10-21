import SwiftUI

struct AddJournalView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss

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
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        viewModel.submitJournal()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !viewModel.isSubmitting && viewModel.journal.error == nil {
                                dismiss()
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
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    AddJournalView()
        .environmentObject(JournalViewModel(settings: AppSettings.loadFromUserDefaults()))
}
