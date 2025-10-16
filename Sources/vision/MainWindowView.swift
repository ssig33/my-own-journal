import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.openWindow) private var openWindow

    init() {
        self.viewModel = JournalViewModel(settings: AppSettings.loadFromUserDefaults())
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("ここにジャーナル機能を実装予定")
                    .font(.title)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("設定") {
                        openWindow(id: "settings")
                    }
                }
            }
            .navigationTitle("ジャーナル")
        }
    }
}

#Preview {
    MainWindowView()
}
