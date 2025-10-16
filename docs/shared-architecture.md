# Shared 層のアーキテクチャ

このドキュメントでは、`Sources/Shared` ディレクトリにあるモデル、ビューモデル、サービスの構造と機能について説明します。

## ディレクトリ構成

```
Sources/Shared/
├── Models/                        # モデル層
│   ├── JournalEntryModel.swift
│   ├── SearchResultModel.swift
│   ├── AppSettingsModel.swift
│   └── SpotlightIndexModel.swift
│
├── ViewModels/                    # ビューモデル層
│   ├── JournalViewModel.swift
│   ├── EditViewModel.swift
│   ├── SearchViewModel.swift
│   └── SettingsViewModel.swift
│
└── Services/                      # サービス層
    ├── GitHubService.swift
    └── SpotlightService.swift
```

## アーキテクチャ概要

このアプリケーションは3層アーキテクチャで構成されています。

```
┌─────────────────────────────────────────┐
│         View 層 (Sources/iOS)            │
│  - SwiftUI による UI 実装                 │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│      ViewModel 層 (Sources/Shared)       │
│  - ビジネスロジック                        │
│  - 状態管理 (@Published)                 │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│       Service 層 (Sources/Shared)        │
│  - GitHub API 連携                       │
│  - Spotlight インデックス管理             │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│        Model 層 (Sources/Shared)         │
│  - データ構造定義                         │
│  - 永続化ロジック                         │
└─────────────────────────────────────────┘
```

---

## Model 層

### JournalEntryModel

**ファイル:** `Sources/Shared/Models/JournalEntryModel.swift`

ジャーナルエントリのデータ構造を定義します。

```swift
struct JournalEntry {
    var content: String       // ジャーナル本文
    var isLoading: Bool      // 読み込み中フラグ
    var error: String?       // エラーメッセージ
}
```

**主要機能:**
- UI に表示するための状態情報を保持
- 空のジャーナルエントリを生成する `empty` 静的プロパティ

---

### SearchResultModel

**ファイル:** `Sources/Shared/Models/SearchResultModel.swift`

GitHub リポジトリ内のファイル/ディレクトリ検索結果を表現します。

```swift
struct SearchResult: Identifiable {
    let id = UUID()
    let name: String           // ファイル/ディレクトリ名
    let path: String           // フルパス
    let type: FileType        // ファイルタイプ
    var content: String?      // ファイル内容（遅延読み込み）
    var isLoading: Bool       // 読み込み中フラグ
    var error: String?        // エラーメッセージ

    enum FileType {
        case directory
        case file
    }
}
```

**主要機能:**
- `Identifiable` プロトコルに準拠（SwiftUI リスト表示に対応）
- ファイル内容の遅延読み込みに対応
- ディレクトリとファイルの区別

---

### AppSettingsModel

**ファイル:** `Sources/Shared/Models/AppSettingsModel.swift`

アプリケーション設定を管理します。

```swift
struct AppSettings {
    var githubPAT: String                      // GitHub Personal Access Token
    var repositoryName: String                 // オーナー名/リポジトリ名
    var journalRule: String                    // ジャーナルパステンプレート
    var lastSpotlightIndexUpdate: Date?        // Spotlight 最終更新日時
    var indexedFilesCount: Int                 // インデックス登録ファイル数
}
```

**主要機能:**

1. **UserDefaults への永続化**
   - `saveToUserDefaults()`: 設定を保存
   - `loadFromUserDefaults()`: 設定を読み込み

2. **設定完了状態の判定**
   - `isConfigured`: すべての必須設定が入力されているかチェック

3. **ジャーナルルール展開**
   - `expandJournalRule(for:)`: テンプレートを実際の日付パスに変換
   - 対応プレースホルダー: `YYYY`, `MM`, `DD`
   - 例: `log/YYYY/MM/DD.md` → `log/2025/10/16.md`

4. **Spotlight インデックス情報の更新**
   - `updateSpotlightInfo(date:count:)`: 更新日時とファイル数を記録

---

### SpotlightIndexModel

**ファイル:** `Sources/Shared/Models/SpotlightIndexModel.swift`

CoreSpotlight とのデータ連携モデルです。

```swift
struct SpotlightIndexItem: Identifiable {
    let id = UUID()
    let name: String          // ファイル名
    let path: String          // ファイルパス
    let content: String       // ファイル内容
    let dateCreated: Date     // 作成日時
}
```

**主要機能:**
- `toSearchableItem()`: `CSSearchableItem` への変換
- `fromActivity(_:)`: Spotlight 検索結果からのパス抽出

**検索可能な情報:**
- ファイル名（タイトル）
- ファイル内容（本文）
- ファイルパス（補足情報）

---

## ViewModel 層

### JournalViewModel

**ファイル:** `Sources/Shared/ViewModels/JournalViewModel.swift`

ジャーナル作成画面のビジネスロジックを管理します。

```swift
class JournalViewModel: ObservableObject {
    @Published var journal = JournalEntry.empty
    @Published var inputText = ""
    @Published var isSubmitting = false
    @Published var showCommitInfo = false
}
```

**主要メソッド:**

1. **`loadJournal()`**
   - 当日のジャーナルを GitHub から読み込み
   - 設定が未完了の場合はエラー表示

2. **`submitJournal()`**
   - ジャーナルエントリを GitHub に送信
   - フロー:
     1. 最新の SHA を取得（競合検出用）
     2. エントリをフォーマット（`-` で始まる箇条書き、または `-----` 区切りのブロック）
     3. GitHub API でファイル更新
     4. 成功時: コミット完了通知を3秒間表示
     5. 409エラー時: 競合を通知

**使用箇所:** `MainView`

---

### EditViewModel

**ファイル:** `Sources/Shared/ViewModels/EditViewModel.swift`

ファイル編集画面のビジネスロジックを管理します。

```swift
class EditViewModel: ObservableObject {
    @Published var journalContent = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var conflictDetected = false
    @Published var latestContent: String?
}
```

**主要メソッド:**

1. **`loadJournal()`**
   - ジャーナルファイルを読み込み

2. **`refreshFileContent(path:)`**
   - 指定ファイルの最新内容と SHA を取得

3. **`saveJournal()`**
   - ジャーナルファイルを保存

4. **`saveFile(path:)`**
   - 指定パスのファイルを保存
   - 409エラー時: `handleConflict(path:)` を呼び出し

5. **`handleConflict(path:)`**
   - コンフリクト検出時の対応
   - 最新コンテンツを再取得して `latestContent` に格納

6. **`acceptLatestContent()`**
   - 最新版を採用（編集内容を破棄）

7. **`keepMyChanges()`**
   - 自分の変更を維持（警告表示あり）

**コンピューテッドプロパティ:**
- `hasChanges`: 編集内容に変更があるかチェック

**使用箇所:** `EditView`

---

### SearchViewModel

**ファイル:** `Sources/Shared/ViewModels/SearchViewModel.swift`

検索・ファイル閲覧画面のビジネスロジックを管理します。

```swift
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var selectedFile: SearchResult?
    @Published var isSearching = false
    @Published var currentPath = ""
    @Published var newFileName = ""
}
```

**主要メソッド:**

1. **`search()`**
   - ファイル内容またはファイル名で検索
   - クエリが空の場合: ルートディレクトリを表示

2. **`searchRootDirectory()`**
   - ルートディレクトリの内容を取得

3. **`getDirectoryContents(path:)`**
   - 指定ディレクトリの内容を取得

4. **`selectFile(_:)`**
   - ファイルを選択してその内容を読み込み
   - ディレクトリの場合: ディレクトリ内容を表示
   - ファイルの場合: ファイル内容を表示

5. **`navigateToParentDirectory()`**
   - 親ディレクトリに移動

6. **`openFileByPath(_:)`**
   - Spotlight 検索結果からのファイル直接オープン

7. **`showNewFileForm()`**
   - 新規ファイル作成フォームを表示

8. **`createNewFile()`**
   - 新規ファイルを作成
   - `.md` 拡張子を自動的に追加
   - パスが `/` で終わる場合は `index.md` を作成

**使用箇所:** `SearchView`

---

### SettingsViewModel

**ファイル:** `Sources/Shared/ViewModels/SettingsViewModel.swift`

設定画面のビジネスロジックを管理します。

```swift
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var githubPAT: String
    @Published var repositoryName: String
    @Published var journalRule: String
    @Published var isUpdatingSpotlightIndex = false
}
```

**主要メソッド:**

1. **`saveSettings()`**
   - 設定を UserDefaults に保存

2. **`updateSpotlightIndex()`**
   - Spotlight 検索インデックスを更新
   - `SpotlightService.updateSpotlightIndex()` のラッパー
   - 更新進度を UI に通知

**コンピューテッドプロパティ:**

1. **`isFormValid`**
   - フォーム全体が有効かチェック

2. **`isJournalRuleValid`**
   - ジャーナルルールが有効かチェック
   - `YYYY`, `MM`, `DD` がすべて含まれている必要あり

3. **`expandJournalRule(_:)`**
   - ジャーナルルールを現在の日付で展開
   - 例: `log/YYYY/MM/DD.md` → `log/2025/10/16.md`

**使用箇所:** `SettingsView`

---

## Service 層

### GitHubService

**ファイル:** `Sources/Shared/Services/GitHubService.swift` (630行)

GitHub API との連携を担当するサービスです。

```swift
class GitHubService {
    private let settings: AppSettings
}
```

**主要メソッド:**

| メソッド | 機能 | 使用 API |
|---------|------|--------|
| `searchContent(query:)` | ファイル内容検索 | GitHub Search API |
| `searchFiles(query:)` | ファイル/ディレクトリ一覧取得 | Contents API |
| `getFileContent(path:)` | ファイル内容取得 | Contents API |
| `getFileContentAndSHA(path:)` | ファイル内容と SHA 同時取得 | Contents API |
| `getJournalPath()` | 当日のジャーナルパス生成 | 内部処理 |
| `createDefaultJournalContent()` | デフォルトジャーナル生成 | 内部処理 |
| `formatJournalEntry()` | エントリのフォーマット処理 | 内部処理 |
| `loadJournal()` | ジャーナルファイル読み込み | Contents API |
| `updateFileContent()` | ファイル更新/新規作成 | Contents API (PUT) |
| `updateJournalFile()` | ジャーナルファイル更新 | Contents API (PUT) |

**重要な実装詳細:**

1. **エラーハンドリング**
   - HTTP ステータスコード別の詳細なエラーメッセージ
   - 401: 認証エラー
   - 403: アクセス拒否
   - 404: ファイル/リポジトリが見つからない
   - 409: ファイル競合（他の場所で編集されている）
   - 422: 処理不可能なリクエスト

2. **Base64 エンコード/デコード**
   - GitHub API はファイル内容を Base64 で送受信
   - `getFileContent()`: Base64 → UTF-8 文字列
   - `updateFileContent()`: UTF-8 文字列 → Base64

3. **キャッシュ制御**
   - `Cache-Control: no-cache` ヘッダーを追加
   - `If-None-Match: ""` で ETag キャッシュを無効化
   - リアルタイムな最新情報を取得

4. **ファイル競合検出**
   - SHA による楽観的ロック実装
   - ファイル更新時に SHA が一致しない場合、409 エラー

5. **日付判定ロジック**
   - 午前2時までを前日として扱う特殊ロジック
   - `getJournalPath()` で使用

6. **ジャーナルエントリフォーマット**
   - 改行が含まれる場合: `-----` 区切りのブロック形式
   - 改行が含まれない場合: `- テキスト` 形式

---

### SpotlightService

**ファイル:** `Sources/Shared/Services/SpotlightService.swift` (165行)

CoreSpotlight とのインデックス連携を担当するサービスです。

```swift
class SpotlightService {
    private let githubService: GitHubService
}
```

**主要メソッド:**

1. **`updateSpotlightIndex()`**
   - Spotlight インデックス更新のメインメソッド
   - フロー:
     1. 既存インデックスを削除
     2. リポジトリを再帰的にクロール
     3. Markdown ファイル（`.md`）のみ処理
     4. ファイル内容を Spotlight に追加
   - 成功時: インデックス登録ファイル数を返却

2. **`crawlRepositoryAndIndex()`**
   - リポジトリを再帰的にクロール
   - `DispatchGroup` を使用して非同期処理を調整
   - ディレクトリとファイルを分離処理
   - エラー集約機能

3. **`deleteAllSpotlightIndices()`**
   - 既存の Spotlight インデックスをすべて削除

4. **`getPathFromSpotlightUserActivity(_:)`**
   - Spotlight 検索結果からファイルパスを抽出

**並行処理の実装:**
- `DispatchGroup` で複数のディレクトリを並行クロール
- エラーは配列に集約し、すべての処理完了後にまとめて通知

**Spotlight 統合:**
- ドメイン識別子: `com.ssig33.myownjournal`
- 検索可能属性:
  - タイトル: ファイル名
  - 本文: ファイル内容
  - 補足情報: ファイルパス

---

## 依存関係図

```
┌─────────────────────────────────────────┐
│          View 層 (iOS)                   │
│  MainView, EditView, SearchView, etc.   │
└────────────┬────────────────────────────┘
             │
      ┌──────┴───────┬─────────┬─────────┐
      │              │         │         │
┌─────▼─────┐ ┌─────▼──┐ ┌───▼───┐ ┌───▼───┐
│Journal    │ │Edit    │ │Search │ │Settings│
│ViewModel  │ │ViewModel│ │ViewModel│ │ViewModel│
└─────┬─────┘ └─────┬──┘ └───┬───┘ └───┬───┘
      │             │        │         │
      └─────────────┴────────┴─────────┘
                    │
      ┌─────────────┴──────────────┐
      │                            │
┌─────▼──────┐            ┌───────▼────────┐
│GitHub      │            │Spotlight       │
│Service     │◄───────────│Service         │
└─────┬──────┘            └────────────────┘
      │
┌─────▼──────────────────────────────────┐
│           Model 層                      │
│  JournalEntry, SearchResult,           │
│  AppSettings, SpotlightIndexItem       │
└────────────────────────────────────────┘
```

---

## 主要な処理フロー

### ジャーナル投稿フロー

```
1. ユーザーがテキスト入力 → 送信ボタンをタップ
   ↓
2. JournalViewModel.submitJournal() 実行
   ↓
3. GitHubService.getFileContentAndSHA() で最新の SHA 取得
   ↓
4. GitHubService.formatJournalEntry() でエントリをフォーマット
   ↓
5. GitHubService.updateFileContent() でファイル更新
   ↓
6a. 成功時:
    - showCommitInfo = true → 3秒後に自動消去
    - ジャーナルを再読み込み
   ↓
6b. 失敗時（409 Conflict）:
    - エラーメッセージを表示
    - ユーザーに再試行を促す
```

### ファイル編集・コンフリクト解決フロー

```
1. ユーザーが EditView でファイルを編集
   ↓
2. EditViewModel.saveFile(path:) 実行
   ↓
3. GitHubService.updateFileContent() でファイル更新
   ↓
4a. 成功時:
    - onSave コールバック実行
    - EditView を閉じる
   ↓
4b. 失敗時（409 Conflict）:
    - EditViewModel.handleConflict(path:) 実行
    - GitHubService.getFileContentAndSHA() で最新内容取得
    - conflictDetected = true
    - latestContent に最新版を格納
   ↓
5. ユーザーに選択肢を提示:
   a) "最新の内容を表示" → Sheet で最新版を表示
      → "最新の内容を採用" → acceptLatestContent()
   b) "自分の変更を維持" → keepMyChanges()
      → 再度保存を試行
```

### Spotlight インデックス更新フロー

```
1. ユーザーが "検索インデックスを更新" ボタンをタップ
   ↓
2. SettingsViewModel.updateSpotlightIndex() 実行
   ↓
3. SpotlightService.updateSpotlightIndex() 実行
   ↓
4. SpotlightService.deleteAllSpotlightIndices()
   - 既存インデックスを削除
   ↓
5. SpotlightService.crawlRepositoryAndIndex()
   - リポジトリを再帰的にクロール
   ↓
6. 各ディレクトリに対して:
   a) GitHubService.searchFiles() でファイル一覧取得
   b) ディレクトリ: 再帰的にクロール
   c) .md ファイル: GitHubService.getFileContent() で内容取得
   ↓
7. SpotlightIndexItem を CSSearchableItem に変換
   ↓
8. CSSearchableIndex.indexSearchableItems() でインデックス登録
   ↓
9. 成功時:
   - AppSettings.updateSpotlightInfo() で情報更新
   - SettingsViewModel に完了通知
   - UI にファイル数を表示
```

---

## 技術的ポイント

### 1. エラーハンドリング
- HTTP ステータスコード別の詳細なエラーメッセージ
- エラー情報を `@Published` プロパティで UI に伝達
- ユーザーフレンドリーなエラーメッセージ

### 2. 並行処理
- `DispatchGroup` による非同期タスク制御
- `[weak self]` パターンによるメモリリーク防止

### 3. キャッシュ制御
- API レスポンスをリアルタイムに取得
- `Cache-Control` と `If-None-Match` ヘッダーによる制御

### 4. 楽観的ロック
- SHA による競合検出
- 409 エラー時のコンフリクト解決フロー

### 5. 状態管理
- `@Published` プロパティで SwiftUI との双方向バインディング
- 読み込み中、保存中などの状態を UI に反映

### 6. 日付処理
- 午前2時までを前日として扱う特殊ロジック
- ジャーナルパステンプレートの柔軟な展開

---

## 参考リンク

- iOS View 層の構造については `docs/ios-views.md` を参照
