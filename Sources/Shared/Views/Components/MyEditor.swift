import SwiftUI
import CodeEditor

struct MyEditor: View {
    @Binding var source: String
    @Environment(\.colorScheme) var colorScheme
    @State private var showPreview: Bool = false

    var body: some View {
        #if canImport(UIKit)
        MyEditorContainer(
            content: {
                if showPreview {
                    MarkdownView(markdown: source)
                } else {
                    CodeEditor(
                        source: $source,
                        language: .markdown,
                        theme: colorScheme == .dark ? .ocean : .atomOneLight
                    )
                }
            },
            fab: {
                Button(action: {
                    showPreview.toggle()
                }) {
                    Image(systemName: showPreview ? "pencil" : "doc.text.magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
            }
        )
        #elseif canImport(AppKit)
        ZStack(alignment: .bottomTrailing) {
            if showPreview {
                MarkdownView(markdown: source)
            } else {
                CodeEditor(
                    source: $source,
                    language: .markdown,
                    theme: colorScheme == .dark ? .ocean : .atomOneLight
                )
            }

            Button(action: {
                showPreview.toggle()
            }) {
                Image(systemName: showPreview ? "pencil" : "doc.text.magnifyingglass")
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
        #endif
    }
}

#if canImport(UIKit)
struct MyEditorContainer<Content: View, FAB: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let fab: () -> FAB

    var body: some View {
        ZStack {
            ScrollView {
                content()
                    .frame(minHeight: UIScreen.main.bounds.height + 120)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fab()
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                }
            }
        }
    }
}
#endif
