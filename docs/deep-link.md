# ディープリンク

アプリの外から、設定したリポジトリ内のファイルを直接開ける。iOS・macOS・visionOS で使える。

## URL の形式

```text
myownjournal://open?path=<リポジトリ内のパス>
```

- `path` はリポジトリのルートからのパス。先頭の `/` は付けても付けなくてもよい
- 日本語・空白・`&` などを含むパスは percent-encoding する
- アプリの設定 (PAT・リポジトリ名) が済んでいる必要がある

例:

```text
myownjournal://open?path=log/2026/10/24.md
myownjournal://open?path=notes/%E6%97%A5%E8%A8%98.md
```

## 開いたときの動き

| プラットフォーム | 動き |
| --- | --- |
| iOS | 検索タブに切り替わり、一覧がファイルの親ディレクトリになり、ファイルの編集画面が開く |
| macOS | メインウィンドウが受け取り、ファイルのウィンドウを開く |
| visionOS | メインウィンドウが受け取り、ファイルのウィンドウを開く |

アプリが起動していなくても、起動中でも開ける。起動中に別のファイルの URL を開くと、そのファイルに切り替わる。

## 使い方の例

- Safari のアドレスバーやメモ・カレンダーのリンクに URL を書く
- ショートカット App の「URL を開く」アクションに URL を渡す
- macOS のターミナルから開く

  ```sh
  open "myownjournal://open?path=log/2026/10/24.md"
  ```

- Simulator で開く

  ```sh
  xcrun simctl openurl <device> "myownjournal://open?path=README.md"
  ```

Safari や `simctl openurl` から開くと、iOS・visionOS は「"…" で開きますか?」と確認してくる。

## Spotlight 検索

設定画面の「検索インデックスの更新」で、リポジトリ内の Markdown ファイルが Spotlight に登録される。
検索結果をタップすると、ディープリンクと同じ動きでそのファイルを開く。
Spotlight の項目の `uniqueIdentifier` にはファイルのパスがそのまま入っている。

## 実装

- URL と Spotlight の `NSUserActivity` からパスを取り出す処理は `Sources/Shared/DeepLink.swift`
- URL scheme `myownjournal` は `project.yml` の各アプリ target の `CFBundleURLTypes` で登録している
- iOS は `ContentView` の `onOpenURL` / `onContinueUserActivity` で受け、`SearchView` に渡す
- macOS・visionOS はメインウィンドウの `onOpenURL` / `onContinueUserActivity` で受け、`openWindow(value:)` でファイルのウィンドウを開く。
  URL はメインウィンドウだけが受けるよう、`handlesExternalEvents` で振り分けている

## テスト

- `Tests/DeepLinkTests.swift`: URL と Spotlight の項目からパスを取り出す処理の単体テスト
- `UITests/DeepLinkUITests.swift`: iOS Simulator でアプリにディープリンクを渡し、起動していない状態と起動中の両方で編集画面が開くことを確かめる

UI テストは `make test` で単体テストと一緒に走る。環境変数で GitHub の token を渡すと、
公開リポジトリ `gonzalezreal/swift-markdown-ui` を実際に読み、編集画面にファイルの中身が出ることまで確かめる。
書き込み権限の無いリポジトリなので、自動保存が走っても何も書き換わらない。

```sh
TEST_RUNNER_E2E_GITHUB_TOKEN=$(gh auth token) make test
```
