# TestFlight での配布

iPhone・Mac・Apple Vision Pro には TestFlight の内部テストでアプリを入れる。
内部テスターは自分 1 人だけなので、Beta App Review は無く、アップロードの処理が終わればすぐ入れられる。

3 つのアプリは同じ Bundle ID (`com.ssig33.MyOwnJournal`) なので、App Store Connect では
1 つのアプリに iOS・macOS・visionOS のプラットフォームが並ぶ。

## 手順

```sh
make testflight
```

`testflight` は iOS・macOS・visionOS の順に次を行う。1 つだけ上げるときは
`testflight-iOS`・`testflight-macOS`・`testflight-vision` を使う。

1. `xcodegen generate`
2. scheme を `generic/platform=<platform>` で archive する。build 番号 (`CURRENT_PROJECT_VERSION`) は
   `make` を始めた時刻 (`YYYYMMDD.HHMM`) で、3 つとも同じになる
3. `ExportOptions.plist` に従い、distribution 署名で export して App Store Connect にアップロードする

`EXPORT_OPTIONS` を渡すと別の export 設定を使える。`destination` を `export` にした plist を渡せば、
アップロードせずに `build/export/<scheme>/` へ書き出すだけになる。

署名とアップロードには Xcode にサインインしている Apple ID を使う (`-allowProvisioningUpdates`)。
Apple Distribution 証明書と provisioning profile は Xcode が自動で作る。

## 設定

| 項目 | 場所 | 理由 |
| --- | --- | --- |
| `MARKETING_VERSION` | `project.yml` | App Store Connect は数字を `.` で区切った形式しか受け付けない |
| `CURRENT_PROJECT_VERSION` | `Makefile` が上書きする | 同じバージョンの中で build 番号が増えていく必要がある |
| `ITSAppUsesNonExemptEncryption: false` | `project.yml` の各 target の `info` | アップロードのたびに暗号化の申告を聞かれないようにする |
| `UISupportedInterfaceOrientations` | `project.yml` の iOS target | iPad の multitasking に対応するには 4 方向すべてが要る |
| `LSApplicationCategoryType` | `project.yml` の macOS target | Mac アプリのアップロードに要る |
| App Sandbox と `network.client` | `project.yml` の macOS target の entitlements | App Store Connect に上げる Mac アプリに必須。GitHub API との通信に `network.client` を使う |
| `testFlightInternalTestingOnly` | `ExportOptions.plist` | 内部テスト専用の build にする |
| `manageAppVersionAndBuildNumber: false` | `ExportOptions.plist` | build 番号を Xcode に書き換えさせない |

sandbox の中では UserDefaults の保存先がアプリの container になる。

export は内部で `/usr/bin/rsync` を呼び、PATH で見つかった rsync をリモート側として起動する。
Homebrew の rsync (3.x) が先に見つかるとオプションの違いで失敗する (`exportArchive Copy failed`) ので、
`Makefile` は export だけ `/usr/bin` を PATH の先頭にして実行する。

## build の期限

TestFlight の build は 90 日で期限が切れる。それまでに新しい build を上げる。
