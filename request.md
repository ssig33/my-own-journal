# これはAIさんへの私の要望である

#  実装方針
- 抽象化機構などは一切つくらない。すべてAPIを直接叩く。
- ビルドとテストは私が自分で手で行なう。AIさんは、コードを書き終わったら私の確認作業を待つべきである。

# 以下のようなiOSアプリをつくりたい
SwitftUI ですべての画面を作成してください

## 初回起動時には設定画面が開きます(初回以外はボトムナビゲーションから遷移できる)
- 初回っていうか必要な設定が全部うまるまで設定画面しか開けない(ナビゲーション無効化)

- GithubのPAT
- リポジトリ名
- ジャーナルの記録ルール
  - サンプルとして log/YYYY/MM/DD.md とかそんなかんじ。 YYYY MM DD が含まれていることは必須


## 設定がうまるとなにがおこなわれるか?
メイン画面、閲覧画面を開くことができる。

### メイン画面の機能 1
- ジャーナルファイルが(あれば)取得しなければ # YYYY-MM-DD という内容の空テキストを用意する
  - yyyy mm dd は今日の日付でうめる、つまり動的にきまるわけ
  - 午前2時までは前日の日付として扱う
- それを表示する(プレーンテキストで表示するだけでいい)

## メイン画面の機能 2
- 2 って書いたけど1より上に表示する。

画面上部にはテキストエリアと送信ボタンがある。

### 送信ボタンが押されたときの動作
- テキストエリアの内容を取得する
- それが一行であれば "- #{テキストエリアの内容}" という形式でジャーナルファイルに追記する
- それが複数行であれば "-----" で区切って、その下にテキストエリアの内容を追記する
- Github API 経由で↑の変更をリポジトリにコミットする。コミットメッセージは "Add journal" とする

## 閲覧画面の機能
閲覧画面ではリポジトリを検索して、ファイルを選択してその内容を表示することができる。

閲覧画面は初期状態では以下のようになっている

- emptystate
- 検索フォーム(ボトムナビの上に固定)

検索フォームに文字を入れて、検索ボタンを押すと、以下の状態になる

- List
  - ここには検索結果が表示される
- 検索フォーム(ボトムナビの上に固定)

リストをタップすると、表示モードに移行する。

そのときは

- ファイル名
- MarkdownView
- 検索フォーム(ボトムナビの上に固定)

という状態になる。  => この状態からさらに編集に遷移できる。編集画面への遷移は右上のボタンからいく。
編集画面は、ファイル名とテキストエリアがあるだけの画面で、保存ボタンを押すと、その内容でファイルが更新される。 => 閲覧ビューに戻る。

そこで検索フォームを押すと

- List
  - ここには検索結果が表示される
- 検索フォーム(ボトムナビの上に固定)

に戻る。

## Spotlight検索
- Github リポジトリをクロールして、Spotlight検索で検索できるようにする
- これは、設定画面に「検索インデックスの更新」ボタンをつくって、それを押すと実行されるようにする
  - そのタイミングで全部過去のインデックスを削除して、新しいインデックスを作成する
- 検索結果をタップすると、閲覧画面に遷移する(つまりディープリンクというか、そういう遷移ができるような機能が検索閲覧画面に必要)