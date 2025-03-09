import Foundation

// ジャーナルデータモデル
struct JournalEntry {
    var content: String
    var isLoading: Bool
    var error: String?
    
    static let empty = JournalEntry(content: "", isLoading: false, error: nil)
}