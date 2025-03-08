import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack() {
            Text("ハロー")
                .font(.largeTitle)
                .padding()
            
            Text("コンニチワ")
                .font(.title)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}

@main
struct MyOwnJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

