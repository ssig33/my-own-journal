import SwiftUI
import CodeEditor

struct MyEditor: View {
    @Binding var source: String
    @Environment(\.colorScheme) var colorScheme
    @State private var showPreview: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if showPreview {
                MarkdownPreviewView(source: $source, showPreview: $showPreview)
            } else {
                CodeEditor(
                    source: $source,
                    language: .markdown,
                    theme: colorScheme == .dark ? .ocean : .atomOneLight
                )

                Button(action: {
                    showPreview = true
                }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
    }
}

private struct MarkdownPreviewView: View {
    @Binding var source: String
    @Binding var showPreview: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                Text(source)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: {
                showPreview = false
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .buttonStyle(.plain)
            .padding(16)
        }
    }
}
