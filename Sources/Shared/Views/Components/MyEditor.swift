import SwiftUI
import CodeEditor

struct MyEditor: View {
    @Binding var source: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        CodeEditor(
            source: $source,
            language: .markdown,
            theme: colorScheme == .dark ? .ocean : .atomOneLight
        )
    }
}
