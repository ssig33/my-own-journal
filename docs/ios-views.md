# iOS View 層の画面機能

このドキュメントでは、`Sources/iOS` ディレクトリにある View ファイルと各画面の機能について説明します。

## ディレクトリ構成

```
Sources/iOS/
├── AppDelegate.swift              # アプリケーションエントリーポイント
├── ContentView.swift              # ルートタブビュー
├── MainView.swift                 # ジャーナル作成画面
├── EditView.swift                 # ファイル編集画面
├── SearchView.swift               # 検索・ファイル閲覧画面
├── SettingsView.swift             # 設定画面
├── MarkdownView.swift             # Markdown レンダリングコンポーネント
└── KeyboardDismissExtension.swift # キーボード制御ユーティリティ
```

## 画面構成

### ContentView - ルートタブビュー

アプリケーションのメインコンテナで、3つのタブを管理します。

**タブ構成:**
- タブ 0: ジャーナル作成（MainView）
- タブ 1: 設定（SettingsView）
- タブ 2: 検索・閲覧（SearchView）

**設定状態による表示制御:**
- 設定未完了時: ジャーナルタブと検索タブに「設定を完了してください」のプレースホルダーを表示
- 設定完了時: すべてのタブが利用可能

**Spotlight 統合:**
- `onContinueUserActivity` で Spotlight 検索結果からのアプリ起動に対応
- 検索結果からファイルパスを抽出し、SearchView に遷移

**実装ファイル:** `Sources/iOS/ContentView.swift`

---

### MainView - ジャーナル作成画面

当日のジャーナルを表示し、新しいエントリを追記する画面です。

#### 主要機能

**1. ジャーナル表示エリア（上部）**
- Markdown 形式でジャーナル内容をレンダリング
- リロードボタン: 最新のジャーナルを GitHub から取得
- 編集ボタン: EditView をモーダル表示してジャーナル全体を編集

**2. 入力エリア（下部）**
- TextEditor による複数行入力に対応
- 動的な高さ調整:
  - 空欄時: 40pt
  - 複数行または50文字以上: 120pt に拡大
- プレースホルダー: "ジャーナルに追記"
- グラデーション枠線（青～紫）

**3. 送信ボタン**
- 単行時: 円形アイコンボタン（右上配置）
- 拡張時: 「送信」テキスト付きボタン（下部配置）
- spring アニメーションで形状を変形

**4. 状態表示（ZStack による重ね合わせ）**
- 通常状態: ジャーナルコンテンツ表示
- 読み込み中: ProgressView + "GitHub からジャーナルを取得しています"
- 送信中: ProgressView + "GitHub にジャーナルを送信しています"
- コミット完了: 緑色の通知（チェックマーク + "コミット完了"）
- エラー: 赤色のエラーメッセージ + 再読み込みボタン

#### デザイン要素
- 送信ボタン背景に透明な白い円を配置（テキストとの重なり防止）
- シャドウとグラデーション効果
- キーボード自動閉じ機能

**使用 ViewModel:** `JournalViewModel`
**実装ファイル:** `Sources/iOS/MainView.swift`

---

### SearchView - 検索・ファイル閲覧画面

GitHub リポジトリ内のファイルを検索し、内容を表示・編集する画面です。

#### 主要機能

**1. 4つの表示状態**
- Empty State: "検索してファイルを表示"
- 検索結果リスト表示
- ファイル内容表示
- 読み込み中表示

**2. 検索フォーム（下部固定）**
- TextField: 検索キーワード入力
- 検索ボタン: ファイル内容またはファイル名で検索

**3. 検索結果リスト**
- 親ディレクトリ移動ボタン（"上の階層へ"）
- 新規ファイル作成ボタン
- 検索結果一覧:
  - フォルダアイコン: ディレクトリ（タップでディレクトリ内容を表示）
  - テキストアイコン: ファイル（タップでファイル内容を表示）
  - 検索クエリ入力時のみファイルパスを表示

**4. ファイル内容表示**
- 戻るボタン（検索結果一覧に戻る）
- ファイル名ヘッダー
- リロードボタン
- 編集ボタン（Markdown ファイルのみ）
- Markdown レンダリング表示

**5. 新規ファイル作成（Sheet）**
- ファイルパス入力フィールド
- `.md` 拡張子を自動的に追加
- パスが `/` で終わる場合は `index.md` が追加される
- 作成中のプログレス表示

#### フロー
1. 検索クエリ入力 → 検索実行
2. 検索結果からファイル選択 → ファイル内容表示
3. ファイル内容から編集ボタン → EditView をモーダル表示
4. 編集保存 → ファイル内容を再読み込み

**使用 ViewModel:** `SearchViewModel`
**実装ファイル:** `Sources/iOS/SearchView.swift`

---

### EditView - ファイル編集画面

ファイルの内容を編集し、プレビューを確認する画面です。

#### 主要機能

**1. 編集モードとプレビューモード**
- 編集モード: TextEditor でファイル内容を直接編集
- プレビューモード: Markdown レンダリングで表示確認
- ナビゲーションバーの「編集/プレビュー」ボタンで切り替え

**2. 状態表示（ZStack による重ね合わせ）**
- 読み込み中: ProgressView
- 保存中: ProgressView + "GitHub にファイルを保存しています"
- コンフリクト検出: 警告表示 + 選択肢
- エラー: エラーメッセージ + 再読み込みボタン
- 通常: 編集またはプレビュー表示

**3. コンフリクト検出時の対応**

ファイル保存時に他の場所で編集されていた場合（409 Conflict）、以下の選択肢を提供:
- "最新の内容を表示" ボタン: Sheet で最新内容を表示
- "自分の変更を維持" ボタン: 現在の編集内容で強制保存（警告表示あり）

Sheet 内の選択肢:
- "キャンセル": Sheet を閉じる
- "最新の内容を採用": 最新版で上書き

**4. ナビゲーション**
- タイトル: "ファイル編集"
- 左ボタン: "キャンセル"（変更がある場合は確認アラート表示）
- 右ボタン:
  - "編集/プレビュー" トグルボタン
  - "保存" ボタン（変更がある場合のみ有効）

**プロパティ:**
- `filePath: String`: 編集対象ファイルパス
- `onSave: () -> Void`: 保存完了時コールバック

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

**実装ファイル:** `Sources/iOS/MarkdownView.swift`

---

### KeyboardDismissExtension - キーボード制御

View に透明な背景を追加し、タップでキーボードを自動的に閉じる機能を提供します。

**使用方法:**
```swift
SomeView()
    .dismissKeyboardOnTap()
```

**使用箇所:**
- MainView
- EditView
- SearchView
- SettingsView

**実装ファイル:** `Sources/iOS/KeyboardDismissExtension.swift`

---

## View 階層構造

```
ContentView (Root)
├── MainView (Tab 0: ジャーナル)
│   ├── MarkdownView (ジャーナル表示)
│   ├── TextEditor (入力フィールド)
│   └── EditView (Sheet: ジャーナル編集)
│       ├── TextEditor (編集モード)
│       └── MarkdownView (プレビューモード)
│
├── SettingsView (Tab 1: 設定)
│   └── Form
│
└── SearchView (Tab 2: 検索・閲覧)
    ├── 検索結果リスト
    ├── ファイル内容表示
    │   ├── MarkdownView
    │   └── EditView (Sheet: ファイル編集)
    └── 新規ファイル作成フォーム (Sheet)
```

---

## 技術スタック

- **UI Framework:** SwiftUI
- **Web View:** WebKit (WKWebView)
- **Markdown Parser:** markdown-it (CDN)
- **Syntax Highlighting:** highlight.js (CDN)
- **State Management:** @State, @ObservedObject, @Environment
- **Navigation:** TabView, NavigationView, Sheet
- **Gesture:** UITapGestureRecognizer

---

## 参考リンク

- Sources/Shared の構造については `docs/shared-architecture.md` を参照
