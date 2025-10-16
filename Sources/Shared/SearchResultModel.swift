import Foundation

// 検索結果データモデル
struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: FileType
    var content: String?
    var isLoading: Bool = false
    var error: String?
    
    // ファイルタイプ（ディレクトリまたはファイル）
    enum FileType {
        case directory
        case file
    }
    
    // 空の検索結果
    static let empty = SearchResult(name: "", path: "", type: .file)
}