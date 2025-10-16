import SwiftUI

// ジャーナル追記用のモーダルView
struct AddJournalEntryView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) var dismiss
    @State private var textEditorHeight: CGFloat = 120

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 入力エリア
                TextEditor(text: $viewModel.inputText)
                    .frame(minHeight: textEditorHeight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .onChange(of: viewModel.inputText) { newValue in
                        // テキストの内容に応じて高さを調整
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if newValue.contains("\n") || newValue.count > 100 {
                                textEditorHeight = 240
                            } else {
                                textEditorHeight = 120
                            }
                        }
                    }

                Spacer()

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
                    .padding()
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
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                }

                // ボタンエリア
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("キャンセル")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        viewModel.submitJournal()
                        // 送信成功を監視して自動的にモーダルを閉じる
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !viewModel.isSubmitting && viewModel.journal.error == nil {
                                dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("送信")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isSubmitting)
                }
                .padding()
            }
            .navigationTitle("ジャーナル追記")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
