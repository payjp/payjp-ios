# PAY.JP iOS SDK

[![CocoaPods deprecated](https://img.shields.io/badge/CocoaPods-deprecated-lightgrey.svg)](#cocoapods-配信終了について)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
![Build and Test](https://github.com/payjp/payjp-ios/workflows/Build%20and%20Test/badge.svg?branch=master)

オンライン決済サービス「[PAY.JP](https://pay.jp/)」のiOSアプリ組込み用のSDKです。

> **【重要】CocoaPods での配信終了について**
>
> CocoaPods Trunk が 2026年12月2日に読み取り専用となるため、今後 CocoaPods では新しいバージョンを配信できなくなります。
> 最新バージョンをご利用いただくには、[Swift Package Manager](#swift-package-manager-推奨) または [Carthage](#carthage) へ移行してください。
> 詳細は[CocoaPods 配信終了について](#cocoapods-配信終了について)を参照してください。

最新バージョンでは以下を実現するための機能が提供されています。
詳細はドキュメントを参照してください。

- Apple Payアプリ内決済
  - https://pay.jp/docs/apple-pay
- クレジットカードによる決済
  - https://pay.jp/docs/mobileapp-ios

| `.tableStyled` | `.labelStyled` | `.displayStyled` |
| - | - | - |
| <img alt="tableStyled" width=240 src="https://user-images.githubusercontent.com/38201241/82025679-a2614580-96cc-11ea-86c5-9eecc0122bc8.png" /> | <img alt="labelStyled" width=240 src="https://user-images.githubusercontent.com/38201241/82025696-a5f4cc80-96cc-11ea-9313-a42896ecd783.png" /> | <img alt="displayStyled" width=240 src="https://user-images.githubusercontent.com/38201241/82026803-3849a000-96ce-11ea-9a8a-eff7ab017060.png" /> |

## サンプルコード

- Apple Pay: https://github.com/payjp/apple-pay-example
- CreditCard (Swift, SPM): https://github.com/payjp/payjp-ios/tree/master/example-swift
- CreditCard (Swift, Carthage): https://github.com/payjp/payjp-ios/tree/master/example-swift (example-swift-carthageターゲット)
- CreditCard (Objective-C, CocoaPods・非推奨): https://github.com/payjp/payjp-ios/tree/master/example-objc

## 動作環境

- Swift または Objective-C で開発された iOS アプリケーション
- iOS 12.0以上
- 最新安定版のXcode

## インストール

### Swift Package Manager (推奨)

Xcode でプロジェクトを開き、以下の手順で追加してください。

1. メニューの **File > Add Package Dependencies...** を選択
2. 検索欄に `https://github.com/payjp/payjp-ios.git` を入力
3. **Dependency Rule** でバージョンを指定し、**Add Package** を選択
4. 利用するターゲットに `PAYJP` を追加

`Package.swift` で管理している場合は、以下のように記述してください。

```swift
dependencies: [
    .package(url: "https://github.com/payjp/payjp-ios.git", from: "<バージョン>")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "PAYJP", package: "PAYJP")
        ]
    )
]
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) でインストールする場合、以下のように記述してください

```
github "payjp/payjp-ios"
```

<details>
<summary>Carthageサンプルアプリのビルド</summary>

example-swift-carthageターゲットをローカルでビルドする場合は、fastlaneを使用してください：

```bash
bundle exec fastlane ios build_carthage_swift_example
```

このlaneは以下を自動的に実行します：
1. PAYJP.xcframeworkの作成（iOSデバイス＋シミュレーター用）
2. 依存ライブラリ（PhoneNumberKit等）のCarthageビルド
3. example-swift-carthageアプリのビルド

注: Package.swiftとの競合により、`carthage bootstrap`だけではビルドできません。fastlaneを使用してください。

</details>

### CocoaPods (非推奨)

> **【重要】** CocoaPods での新しいバージョンの配信は終了予定です。[CocoaPods 配信終了について](#cocoapods-配信終了について)を参照し、Swift Package Manager または Carthage へ移行してください。

[CocoaPods](https://cocoapods.org) でもインストールすることができます。

```ruby
pod 'PAYJP'
```

## CocoaPods 配信終了について

CocoaPods の公開リポジトリ (Trunk) が [2026年12月2日に読み取り専用になる](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)ことに伴い、PAY.JP iOS SDK は CocoaPods での配信を終了します。

- 配信終了前に公開済みのバージョンは、引き続き CocoaPods でインストールできます。
- 配信終了後に公開される新しいバージョンは、CocoaPods では取得できません。
- 最新のバージョンや機能追加・修正を利用するには、Swift Package Manager または Carthage への移行が必要です。

### CocoaPods から Swift Package Manager への移行

1. `Podfile` から `pod 'PAYJP'` を削除し、`pod install` を実行する
2. 上記の[Swift Package Manager](#swift-package-manager-推奨)の手順で `PAYJP` を追加する
3. アプリのビルドと動作を確認する

## SDK開発環境

- Swift 5

## リファレンス

- https://payjp.github.io/payjp-ios/

## License

PAY.JP iOS SDK is available under the MIT license. See the LICENSE file for more info.
