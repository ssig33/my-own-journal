import Foundation

// エディタの保存後に出すステータス表示
enum SaveStatus {
    // ステータスを表示しておく秒数
    static let displayDuration: TimeInterval = 3.0

    // 保存結果のメッセージ。成功なら保存した時刻、失敗ならエラーの内容を添える
    static func message(success: Bool, error: String?, at date: Date = Date(), timeZone: TimeZone = .current) -> String {
        guard success else {
            if let error = error {
                return "保存失敗: \(error)"
            }
            return "保存失敗"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return "保存完了: \(formatter.string(from: date))"
    }
}
