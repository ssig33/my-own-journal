import SwiftUI
import UIKit

// キーボードを閉じるための拡張機能
extension View {
    /// タップでキーボードを閉じる機能を追加する
    func dismissKeyboardOnTap() -> some View {
        return self.background(DismissKeyboardBackground())
    }
}

// キーボードを閉じるための背景View
struct DismissKeyboardBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // タップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.cancelsTouchesInView = false // 他のタッチイベントをキャンセルしない
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        @objc func handleTap() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// キーボードを閉じるためのグローバル関数
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}