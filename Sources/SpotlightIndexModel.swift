import Foundation
import CoreSpotlight
import MobileCoreServices

// Spotlight検索用のデータモデル
struct SpotlightIndexItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let content: String
    let dateCreated: Date
    
    // CSSearchableItemからSpotlightIndexItemを作成するイニシャライザ
    init?(searchableItem: CSSearchableItem) {
        // attributeSetはオプショナル型として扱う
        guard let attributeSet = searchableItem.attributeSet as? CSSearchableItemAttributeSet,
              let name = attributeSet.title,
              let path = attributeSet.contentURL?.absoluteString.removingPercentEncoding,
              let content = attributeSet.contentDescription else {
            return nil
        }
        
        self.name = name
        self.path = path
        self.content = content
        self.dateCreated = attributeSet.contentCreationDate ?? Date()
    }
    
    // 新規作成用のイニシャライザ
    init(name: String, path: String, content: String, dateCreated: Date = Date()) {
        self.name = name
        self.path = path
        self.content = content
        self.dateCreated = dateCreated
    }
    
    // CSSearchableItemに変換するメソッド
    func toSearchableItem() -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = name
        attributeSet.contentDescription = content
        
        // パスをURLに変換してセット
        if let pathURL = URL(string: path) {
            attributeSet.contentURL = pathURL
        }
        
        attributeSet.contentCreationDate = dateCreated
        
        // 一意のIDを生成（パスをIDとして使用）
        let uniqueIdentifier = "com.ssig33.myOwnJournal.file.\(path.hashValue)"
        
        // ドメインを指定（アプリのバンドルIDを使用するのが一般的）
        let domainIdentifier = Bundle.main.bundleIdentifier ?? "com.ssig33.myOwnJournal"
        
        return CSSearchableItem(uniqueIdentifier: uniqueIdentifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
    }
}