# iOS View 層の画面機能

このドキュメントでは、`Sources/iOS` ディレクトリにある View ファイルと各画面の機能、iOS の画面が使う共通コンポーネントについて説明します。

## ディレクトリ構成

```
Sources/iOS/
├── AppDelegate.swift              # アプリケーションエントリーポイント
├── ContentView.swift              # ルートタブビュー
├── MainView.swift                 # 当日のジャーナルの編集画面
├── EditView.swift                 # ファイル編集画面
├── SearchView.swift               # 検索・ファイル閲覧画面
├── SettingsView.swift             # 設定画面
├── AddJournalEntryView.swift      # ジャーナル追記のモーダル（どの画面からも表示されていない）
└── KeyboardDismissExtension.swift # キーボード制御ユーティリティ

Sources/Shared/Views/Components/
├── MyEditor.swift                 # Markdown エディタとプレビュー切り替え
└── MarkdownView.swift             # Markdown レンダリングコンポーネント
```

## 画面構成

### ContentView - ルートタブビュー

アプリケーションのメインコンテナで、3つのタブを管理します。

**タブ構成（表示順）:**
- ジャーナル（MainView、tag 0）
- 検索（SearchView、tag 2）
- 設定（SettingsView、tag 1）

設定が完了していない状態で起動すると、設定タブを選んだ状態で開きます。

**設定状態による表示制御:**
- 設定未完了時: ジャーナルタブと検索タブに「設定を完了してください」のプレースホルダーを表示
- 設定完了時: すべてのタブが利用可能

**ディープリンク・Spotlight 統合:**
- `onOpenURL` でディープリンク (`myownjournal://open?path=...`)、`onContinueUserActivity` で Spotlight 検索結果からの起動を受ける
- どちらもファイルパスを取り出して検索タブに切り替え、SearchView がそのファイルを編集画面で開く ([deep-link.md](deep-link.md))

**実装ファイル:** `Sources/iOS/ContentView.swift`

---

### MainView - ジャーナル編集画面

当日のジャーナルファイル全体をエディタで直接編集する画面です。

#### 主要機能

**1. ツールバー（上部）**
- タイトル "ジャーナル"
- ステータス表示: "読み込み中"、"保存中"、"保存完了: HH:mm:ss"、"保存失敗: ..."、"読み込み失敗: ..."
- 再読み込みボタン: 当日のジャーナルを GitHub から取得し直す

**2. エディタ**
- `MyEditor` で当日のジャーナル全体を編集する（プレビュー切り替えは MyEditor のフローティングボタン）
- 当日のファイルが無いときは日付見出しだけの初期内容を表示する

**3. 自動保存**
- 編集が止まってから 2 秒後に保存する（`EditViewModel.saveFile`）
- 保存のたびに GitHub から最新の SHA を取得して上書きする
- 内容が読み込んだとき・追記したとき・前回保存したときと同じなら保存しない。当日のファイルが無いときに表示する日付見出しだけの初期内容も、編集するまで保存しない
- 内容を空にしたときは保存せず "保存失敗: 空の内容は保存しません" と表示する
- 保存結果は 3 秒間ステータスに表示する（`SaveStatus`）

**使用 ViewModel:** `JournalViewModel`（読み込み）、`EditViewModel`（保存）
**実装ファイル:** `Sources/iOS/MainView.swift`

---

### SearchView - 検索・ファイル閲覧画面

GitHub リポジトリ内のファイルを検索し、内容を表示・編集する画面です。

#### 主要機能

**1. 表示状態**
- Empty State: "検索してファイルを表示"
- 検索結果リスト表示
- 読み込み中表示（上の 2 つに重ねて表示）

初めて表示したときはリポジトリのルートの一覧を表示します。

**2. 検索フォーム（下部固定）**
- TextField: 検索キーワード入力
- 検索ボタン: ファイル内容またはファイル名で検索

**3. 検索結果リスト**
- 親ディレクトリ移動ボタン（"上の階層へ"）
- 新規ファイル作成ボタン
- 検索結果一覧:
  - フォルダアイコン: ディレクトリ（タップでディレクトリ内容を表示）
  - テキストアイコン: ファイル（タップで EditView をモーダル表示）
  - 検索クエリ入力時のみファイルパスを表示

**4. 新規ファイル作成（Sheet）**
- ファイルパス入力フィールド
- `.md` 拡張子を自動的に追加
- パスが `/` で終わる場合は `index.md` が追加される
- 内容が `# ファイル名` の 1 行のファイルを作る
- 同じパスにファイルが既にあれば作らず、"… は既に存在します" と表示する

#### フロー
1. 検索クエリ入力 → 検索実行、またはディレクトリをたどる
2. 検索結果からファイル選択 → EditView をモーダル表示
3. ディープリンク・Spotlight から開いたファイルも EditView で開く

**使用 ViewModel:** `SearchViewModel`
**実装ファイル:** `Sources/iOS/SearchView.swift`

---

### EditView - ファイル編集画面

ファイルの内容を編集し、自動で保存する画面です。

#### 主要機能

**1. エディタ**
- `MyEditor` でファイル内容を編集する
- 右下のフローティングボタンで編集とプレビューを切り替える

**2. 読み込み**
- 表示時と再読み込みボタンで、GitHub からファイルの内容と SHA を取得する
- 取得が終わった時点で内容をエディタに反映する

**3. 自動保存**
- 編集が止まってから 2 秒後に、読み込んだ（または前回保存した）SHA を付けて保存する
- 保存に成功すると、保存後の SHA と内容を覚えておき、次の保存に使う
- 内容が読み込んだとき・前回保存したときと同じなら保存しない
- 保存結果は 3 秒間ステータスに表示する（`SaveStatus`）

**4. コンフリクト（409）**
- 他の場所で編集されていて保存できなかったときは "保存失敗: ファイルが他の場所で編集されています。…" と表示し、最新の SHA を取得し直す
- 次の自動保存は、取得し直した SHA で編集中の内容を保存する

**5. ナビゲーション**
- タイトル: "ファイル編集"
- 左ボタン: "閉じる"
- 右側: ステータス表示（"読み込み中"、"保存中"、"保存完了: HH:mm:ss"、"保存失敗: ..."、"読み込み失敗: ..."）と再読み込みボタン

**プロパティ:**
- `filePath: String`: 編集対象ファイルパス
- `onSave: () -> Void`: 保存完了時コールバック（iOS の EditView からは呼ばれない）

**使用 ViewModel:** `EditViewModel`
**実装ファイル:** `Sources/iOS/EditView.swift`

---

### SettingsView - 設定画面

アプリケーションの設定を行う画面です。

#### 設定セクション

**1. GitHub 設定**
- GitHub Personal Access Token 入力
- リポジトリ名入力（`owner/repository` 形式）

**2. ジャーナル設定**
- ジャーナルファイルパステンプレート入力
- 例: `log/YYYY/MM/DD.md`
- リアルタイム検証:
  - `YYYY`, `MM`, `DD` が必須（不足時は赤色で警告表示）
  - 有効なルール時: 今日の日付での展開例を表示

**3. Spotlight 検索インデックス**
- 最終更新日時表示
- インデックス登録ファイル数表示
- "検索インデックスを更新" ボタン
  - 更新中のプログレス表示
  - 成功メッセージ（登録ファイル数表示）
  - エラーメッセージ表示

**4. 保存ボタン**
- フォーム入力不完全時は無効化
- 保存時に UserDefaults に設定を永続化

**使用 ViewModel:** `SettingsViewModel`
**実装ファイル:** `Sources/iOS/SettingsView.swift`

---

## 共通コンポーネント

### MyEditor - Markdown エディタ

CodeEditor（`ssig33/CodeEditor`）による Markdown の編集と、MarkdownView によるプレビューを切り替えるコンポーネントです。右下のフローティングボタンで切り替えます。

**使用箇所:** MainView、EditView

**実装ファイル:** `Sources/Shared/Views/Components/MyEditor.swift`

---

### MarkdownView - Markdown レンダリング

Markdown テキストを HTML にレンダリングして表示するコンポーネントです。

**技術スタック:**
- WKWebView (UIViewRepresentable でラップ)
- markdown-it (CDN から読み込み)
- highlight.js (CDN から読み込み)

**主要機能:**
- Markdown → HTML 変換
- シンタックスハイライト（コードブロック対応）
- ライトモード/ダークモード対応
- URL 自動リンク化
- スマートタイポグラフィ

**スタイル:**
- ライトモード: 黒文字、グレー背景コード、青色リンク
- ダークモード: ライトグレー文字、ダークグレー背景、ドラキュラ風シンタックスハイライト

**実装ファイル:** `Sources/Shared/Views/Components/MarkdownView.swift`

---

### KeyboardDismissExtension - キーボード制御

View に透明な背景を追加し、タップでキーボードを自動的に閉じる機能を提供します。

**使用方法:**
```swift
SomeView()
    .dismissKeyboardOnTap()
```

**使用箇所:**
- SearchView
- SettingsView

**実装ファイル:** `Sources/iOS/KeyboardDismissExtension.swift`

---

## View 階層構造

```
ContentView (Root)
├── MainView (ジャーナル)
│   └── MyEditor
│       ├── CodeEditor (編集)
│       └── MarkdownView (プレビュー)
│
├── SearchView (検索・閲覧)
│   ├── 検索結果リスト
│   ├── EditView (Sheet: ファイル編集)
│   │   └── MyEditor
│   └── 新規ファイル作成フォーム (Sheet)
│
└── SettingsView (設定)
    └── Form
```

---

## 技術スタック

- **UI Framework:** SwiftUI
- **Editor:** CodeEditor (`ssig33/CodeEditor`)
- **Web View:** WebKit (WKWebView)
- **Markdown Parser:** markdown-it (CDN)
- **Syntax Highlighting:** highlight.js (CDN)
- **State Management:** @State, @ObservedObject, @Environment
- **Navigation:** TabView, NavigationView, Sheet
- **Gesture:** UITapGestureRecognizer

---

## 参考リンク

- Sources/Shared の構造については `docs/shared-architecture.md` を参照
