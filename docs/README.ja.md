# WhisperPad

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3%2FM4-orange.svg)](https://support.apple.com/ja-jp/HT211814)
[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)

[English](../README.md)

macOS メニューバーに常駐する音声文字起こしアプリケーションです。WhisperKit によるオンデバイス音声認識で、完全にローカルで動作します。

<p align="center">
  <img src="./assets/AppIcon.iconset/icon_512x512.png" alt="icon" />
</p>

## 概要

WhisperPad は、グローバルホットキーで音声録音を開始し、WhisperKit によるオンデバイス音声認識でテキストに変換、クリップボードまたはファイルに出力します。

**プライバシー重視**: すべての処理はローカルで完結し、ネットワーク接続は不要です。音声データが外部に送信されることはありません。

## 主要機能

| 機能                   | 説明                                              |
| ---------------------- | ------------------------------------------------- |
| メニューバー常駐       | システム起動時に自動起動し、メニューバーに常駐    |
| ホットキー録音         | グローバルショートカットで即座に録音開始/停止     |
| オンデバイス文字起こし | WhisperKit による完全ローカル処理                 |
| 柔軟な出力             | クリップボード、ファイル、または両方への出力      |
| モデル切替             | メニューバーから直接 Whisper モデルを切り替え可能 |

## システム要件

| 項目       | 要件                        |
| ---------- | --------------------------- |
| OS         | macOS 14.0+ (Sonoma)        |
| プロセッサ | Apple Silicon (M1/M2/M3/M4) |
| メモリ     | 8GB 以上推奨                |

### 必要な権限

- **マイクアクセス**: 音声録音のため
- **アクセシビリティ**: グローバルホットキーのため

## インストール

### ビルド

```bash
# リポジトリをクローン
git clone https://github.com/your-username/WhisperPad.git
cd WhisperPad

# ビルド
swift build -c release
```

### 開発環境のセットアップ

```bash
# mise をインストール（未インストールの場合）
brew install mise

# 開発ツールをセットアップ
mise install
```

## 使い方

### 基本操作

1. アプリを起動すると、メニューバーにマイクアイコンが表示されます
2. ホットキー（デフォルト: `⌘⌥R`）で録音を開始
3. 再度ホットキーを押すと録音を停止し、文字起こしを開始
4. 完了後、結果がクリップボードにコピーされます

### ホットキー

| ショートカット | 動作                    |
| -------------- | ----------------------- |
| `⌘⌥R`          | 録音開始/停止（トグル） |
| `⌘⌥P`          | 一時停止/再開           |
| `⌘⌥.`          | 録音キャンセル          |

### 録音モード

- **Toggle**: ホットキー 1 回で開始、再度押しで停止

### メニューバーアイコンの状態

| 状態         | アイコン           | 色       |
| ------------ | ------------------ | -------- |
| 待機中       | マイク             | グレー   |
| 録音中       | マイク（波形付き） | 赤       |
| 一時停止中   | 一時停止           | オレンジ |
| 文字起こし中 | 歯車（回転）       | 青       |
| 完了         | チェックマーク     | 緑       |
| エラー       | 警告               | 黄       |

## 設定

設定画面（`⌘,`）から以下の項目をカスタマイズできます：

| タブ      | 内容                                           |
| --------- | ---------------------------------------------- |
| General   | 起動設定、通知、言語、アイドルタイムアウト     |
| Icon      | 各状態のアイコン・色カスタマイズ               |
| Hotkey    | 録音、一時停止、キャンセルのホットキー         |
| Recording | 入力デバイス、オーディオモニタリング、出力設定 |
| Model     | モデル検索・フィルタ、ダウンロード/削除        |

## 開発

### 開発コマンド

```bash
# フォーマット
mise run format          # 全フォーマッター実行
mise run format:swift    # Swift ファイルのみ

# リント
mise run lint            # 全リンター実行
mise run lint:swift      # SwiftLint

# CI チェック（ファイル変更なし）
mise run check

# 自動修正
mise run fix             # フォーマット + リント修正
```

### アーキテクチャ

**The Composable Architecture (TCA)** v1.23.1+ を使用した状態管理を採用しています。

```
WhisperPad/
├── App/            # AppReducer, AppDelegate
├── Features/       # TCA Feature モジュール
│   ├── Recording/      # 音声録音
│   ├── Transcription/  # 文字起こし
│   └── Settings/       # 設定
├── Clients/        # 外部サービス連携
│   ├── AudioRecorderClient   # 録音・マイク権限
│   ├── TranscriptionClient   # WhisperKit 統合
│   ├── HotKeyClient          # グローバルホットキー
│   └── OutputClient          # クリップボード・ファイル出力
└── Models/         # データモデル
```

### コードスタイル

- **SwiftLint** (v0.62.2): 行長 120 文字、関数本体 50 行以内
- **SwiftFormat** (v0.58.7): Swift 5.10、4 スペースインデント

## 依存ライブラリ

| ライブラリ                                                          | バージョン | 用途                 |
| ------------------------------------------------------------------- | ---------- | -------------------- |
| [WhisperKit](https://github.com/argmaxinc/WhisperKit)               | 0.15.0+    | 音声認識             |
| [TCA](https://github.com/pointfreeco/swift-composable-architecture) | 1.23.1+    | 状態管理             |
| [HotKey](https://github.com/soffes/HotKey)                          | 0.2.1+     | グローバルホットキー |
