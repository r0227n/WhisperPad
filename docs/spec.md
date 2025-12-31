# WhisperPad 仕様書

**ドキュメントバージョン**: 1.0  
**作成日**: 2024 年 12 月  
**対象アプリバージョン**: 0.1.0

---

## 目次

1. [概要](#1-概要)
2. [システム要件](#2-システム要件)
3. [アーキテクチャ](#3-アーキテクチャ)
4. [機能仕様](#4-機能仕様)
5. [画面仕様](#5-画面仕様)
6. [状態遷移](#6-状態遷移)
7. [データ仕様](#7-データ仕様)
8. [外部ライブラリ](#8-外部ライブラリ)
9. [セキュリティ・プライバシー](#9-セキュリティプライバシー)
10. [エラーハンドリング](#10-エラーハンドリング)
11. [テスト仕様](#11-テスト仕様)
12. [今後の拡張予定](#12-今後の拡張予定)

---

## 1. 概要

### 1.1 アプリケーション概要

**WhisperPad** は、macOS メニューバーに常駐する音声文字起こしアプリケーションです。グローバルホットキーで音声録音を開始し、WhisperKit によるオンデバイス音声認識でテキストに変換、クリップボードまたはファイルに出力します。

### 1.2 主要機能

| 機能                   | 説明                                                  |
| ---------------------- | ----------------------------------------------------- |
| メニューバー常駐       | システム起動時に自動起動し、メニューバーに常駐        |
| ホットキー録音         | グローバルショートカットで即座に録音開始/停止         |
| オンデバイス文字起こし | WhisperKit による完全ローカル処理（ネットワーク不要） |
| 柔軟な出力             | クリップボード、ファイル、または両方への出力          |

### 1.3 ターゲットユーザー

- 音声でメモを取りたいビジネスユーザー
- 議事録を素早く作成したいユーザー
- タイピングよりも音声入力を好むユーザー
- プライバシーを重視し、クラウドサービスを避けたいユーザー

---

## 2. システム要件

### 2.1 ハードウェア要件

| 項目       | 最小要件           | 推奨要件                |
| ---------- | ------------------ | ----------------------- |
| チップ     | Apple Silicon (M1) | Apple Silicon (M2 以降) |
| メモリ     | 8GB                | 16GB 以上               |
| ストレージ | 2GB 空き容量       | 5GB 以上                |
| マイク     | 内蔵マイク         | 外部マイク推奨          |

### 2.2 ソフトウェア要件

| 項目  | 要件                     |
| ----- | ------------------------ |
| OS    | macOS 14.0 (Sonoma) 以降 |
| Xcode | 15.0 以降（開発時）      |
| Swift | 5.10 以降                |

### 2.3 必要な権限

| 権限                 | 用途                         | 必須/任意 |
| -------------------- | ---------------------------- | --------- |
| マイクアクセス       | 音声録音                     | 必須      |
| アクセシビリティ     | グローバルホットキー         | 必須      |
| フルディスクアクセス | 任意フォルダへのファイル保存 | 任意      |

---

## 3. アーキテクチャ

### 3.1 アーキテクチャパターン

本アプリケーションは **The Composable Architecture (TCA)** を採用します。

```
┌─────────────────────────────────────────────────────────────────┐
│                         WhisperPad                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │ MenuBarView │  │SettingsView │  │  HistoryView    │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘  │   │
│  └─────────┼────────────────┼──────────────────┼───────────┘   │
│            │                │                  │               │
│  ┌─────────┴────────────────┴──────────────────┴───────────┐   │
│  │                     TCA Store                            │   │
│  │  ┌─────────────────────────────────────────────────────┐│   │
│  │  │  AppReducer                                         ││   │
│  │  │  ├── RecordingFeature                               ││   │
│  │  │  ├── TranscriptionFeature                           ││   │
│  │  │  ├── SettingsFeature                                ││   │
│  │  │  └── HistoryFeature                                 ││   │
│  │  └─────────────────────────────────────────────────────┘│   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌───────────────────────────┴─────────────────────────────┐   │
│  │                    Domain Layer                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │AudioRecorder│  │Transcription│  │  OutputManager  │  │   │
│  │  │   Client    │  │   Client    │  │     Client      │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘  │   │
│  └─────────┼────────────────┼──────────────────┼───────────┘   │
│            │                │                  │               │
│  ┌─────────┴────────────────┴──────────────────┴───────────┐   │
│  │                  Infrastructure Layer                    │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────┐ │   │
│  │  │AVFoundation│  │WhisperKit │  │NSPasteboard│  │FileIO│ │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 モジュール構成

```
WhisperPad/
├── App/
│   ├── WhisperPadApp.swift              # アプリエントリーポイント
│   ├── AppDelegate.swift               # AppKit連携・メニューバー管理
│   └── AppReducer.swift                # ルートReducer
│
├── Features/
│   ├── Recording/
│   │   ├── RecordingFeature.swift      # 録音機能Reducer
│   │   └── RecordingView.swift         # 録音状態表示
│   │
│   ├── Transcription/
│   │   ├── TranscriptionFeature.swift  # 文字起こし機能Reducer
│   │   └── TranscriptionView.swift     # 変換状態表示
│   │
│   ├── Settings/
│   │   ├── SettingsFeature.swift       # 設定機能Reducer
│   │   ├── SettingsView.swift          # 設定画面
│   │   ├── GeneralSettingsView.swift   # 一般設定
│   │   ├── HotkeySettingsView.swift    # ホットキー設定
│   │   ├── OutputSettingsView.swift    # 出力設定
│   │   └── ModelSettingsView.swift     # モデル設定
│   │
│   └── History/
│       ├── HistoryFeature.swift        # 履歴機能Reducer
│       └── HistoryView.swift           # 履歴画面
│
├── Clients/
│   ├── AudioRecorderClient.swift       # 音声録音クライアント
│   ├── TranscriptionClient.swift       # WhisperKit連携クライアント
│   ├── HotKeyClient.swift              # ホットキー管理クライアント
│   ├── OutputClient.swift              # 出力処理クライアント
│   └── UserDefaultsClient.swift        # 設定永続化クライアント
│
├── Models/
│   ├── AppState.swift                  # アプリ全体の状態
│   ├── RecordingState.swift            # 録音状態
│   ├── Transcription.swift             # 書き起こしデータ
│   ├── AppSettings.swift               # 設定モデル
│   └── WhisperModel.swift              # Whisperモデル定義
│
├── Views/
│   ├── MenuBarView.swift               # メニューバーUI
│   ├── StatusIconView.swift            # ステータスアイコン
│   └── Components/
│       ├── HotkeyRecorderView.swift    # ホットキー入力UI
│       └── ModelDownloadView.swift     # モデルダウンロード進捗
│
└── Resources/
    ├── Assets.xcassets                 # アイコン・画像
    ├── Localizable.strings             # 日本語ローカライズ
    └── Info.plist                      # アプリ設定
```

### 3.3 依存関係図

```
┌─────────────────────┐
│   WhisperPadApp      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐      ┌─────────────────────┐
│    AppReducer       │◀────▶│      AppState       │
└──────────┬──────────┘      └─────────────────────┘
           │
     ┌─────┴─────┬─────────────┬─────────────┐
     ▼           ▼             ▼             ▼
┌─────────┐ ┌─────────┐ ┌───────────┐ ┌─────────┐
│Recording│ │Transcrip│ │  Settings │ │ History │
│ Feature │ │  tion   │ │  Feature  │ │ Feature │
└────┬────┘ └────┬────┘ └─────┬─────┘ └────┬────┘
     │           │            │            │
     ▼           ▼            ▼            ▼
┌─────────┐ ┌─────────┐ ┌───────────┐ ┌─────────┐
│Audio    │ │Transcrip│ │UserDefaults│ │  File   │
│Recorder │ │  tion   │ │  Client   │ │ Client  │
│ Client  │ │ Client  │ │           │ │         │
└────┬────┘ └────┬────┘ └───────────┘ └─────────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│AVFounda │ │Whisper  │
│  tion   │ │   Kit   │
└─────────┘ └─────────┘
```

---

## 4. 機能仕様

### 4.1 メニューバー機能

#### 4.1.1 メニューバーアイコン

| 状態               | アイコン                   | 色     | 説明                           |
| ------------------ | -------------------------- | ------ | ------------------------------ |
| 未起動（アイドル） | マイクアイコン             | グレー | 待機中                         |
| 音声収録中         | マイクアイコン（波形付き） | 赤     | 録音中を示す                   |
| 文字起こし中       | 歯車アイコン（回転）       | 青     | 処理中を示す                   |
| 処理完了           | チェックマーク             | 緑     | 完了（3 秒後にアイドルに戻る） |
| エラー             | 警告アイコン               | 黄     | エラー発生                     |

#### 4.1.2 メニュー項目

```
┌─────────────────────────────────────┐
│ WhisperPad                           │
├─────────────────────────────────────┤
│ ● 録音開始              ⌥ Space    │  ← 状態により「録音終了」「一時停止」「再開」に変化
│   ├ 録音中 → 「⏸ 一時停止」「⏹ 録音終了」
│   └ 一時停止中 → 「▶ 再開」「⏹ 録音終了」
├─────────────────────────────────────┤
│ 📊 最後の書き起こし                  │
│    "今日の会議では..."   [コピー]    │
├─────────────────────────────────────┤
│ 📝 履歴                         ▶   │
│    ├ 12:30 会議メモ (1分30秒)       │
│    ├ 10:15 アイデア (45秒)          │
│    └ すべて表示...                  │
├─────────────────────────────────────┤
│ ⚙️  設定...                   ⌘ ,   │
├─────────────────────────────────────┤
│ ❓ ヘルプ                           │
│ 📄 ライセンス                       │
├─────────────────────────────────────┤
│ 終了                          ⌘ Q   │
└─────────────────────────────────────┘
```

### 4.2 ホットキー機能

#### 4.2.1 デフォルトショートカット

| ショートカット     | 動作                       | カスタマイズ |
| ------------------ | -------------------------- | ------------ |
| `⌥ Option + Space` | 録音開始/停止（トグル）    | 可           |
| `⌘ + Shift + V`    | 最後の書き起こしをペースト | 可           |
| `⌘ + Shift + ,`    | 設定を開く                 | 可           |
| `Escape`           | 録音キャンセル             | 不可         |

#### 4.2.2 録音モード

| モード           | 説明           | 動作                                  |
| ---------------- | -------------- | ------------------------------------- |
| **Toggle**       | トグルモード   | ホットキー 1 回で開始、再度押しで停止 |
| **Push-to-Talk** | 押し続けモード | ホットキー押下中のみ録音、離すと停止  |

#### 4.2.3 ホットキー登録仕様

```swift
struct HotKeySettings: Codable, Equatable {
    var recordingHotKey: KeyCombo
    var pasteHotKey: KeyCombo
    var openSettingsHotKey: KeyCombo
    var recordingMode: RecordingMode

    struct KeyCombo: Codable, Equatable {
        var key: UInt32           // キーコード
        var modifiers: UInt32     // 修飾キー（Cmd, Option, Shift, Control）
    }

    enum RecordingMode: String, Codable, CaseIterable {
        case toggle = "toggle"
        case pushToTalk = "push_to_talk"
    }
}
```

### 4.3 音声録音機能

#### 4.3.1 録音設定

| 項目           | 値        | 説明           |
| -------------- | --------- | -------------- |
| サンプルレート | 16,000 Hz | Whisper 推奨値 |
| チャンネル     | モノラル  | Whisper 推奨値 |
| ビット深度     | 16bit     | 標準品質       |
| フォーマット   | WAV (PCM) | 無圧縮         |

#### 4.3.2 録音制限

| 項目             | デフォルト値 | 設定範囲      |
| ---------------- | ------------ | ------------- |
| 最大録音時間     | 60 秒        | 10 秒〜300 秒 |
| 無音検出しきい値 | -40dB        | -60dB〜-20dB  |
| 無音自動停止時間 | 3 秒         | 1 秒〜10 秒   |

#### 4.3.3 録音状態

```swift
enum RecordingStatus: Equatable {
    case idle                           // 待機中
    case preparing                      // 準備中
    case recording(duration: TimeInterval, level: Float)  // 録音中
    case paused(duration: TimeInterval) // 一時停止中
    case stopping                       // 停止処理中
    case cancelled                      // キャンセル
}
```

#### 4.3.4 一時停止・再開機能

録音中に一時停止を行い、後で再開できます。一時停止中は**マイクが完全に解放**され、macOS システムレベルでもマイク使用中と判定されません。

##### 動作方式

一時停止時にマイクを完全に解放するため、**複数セグメント方式**を採用しています：

```text
録音開始  → セグメント0.wav を作成・録音
一時停止  → stop() でマイク完全解放、セグメント0 を保持
再開      → セグメント1.wav を新規作成・録音
再度停止  → stop() でマイク完全解放、セグメント1 を保持
録音終了  → 全セグメントを AVMutableComposition で1ファイルに結合
```

##### 状態遷移

```text
        ┌──────────────┐
        │   recording  │
        │   (録音中)    │
        └───────┬──────┘
                │ pauseRecordingButtonTapped
                │ (stop() → マイク解放)
                ▼
        ┌──────────────┐
        │    paused    │
        │  (一時停止中) │
        └───────┬──────┘
                │ resumeRecordingButtonTapped
                │ (新セグメント開始)
                ▼
        ┌──────────────┐
        │   recording  │
        │   (録音中)    │
        └──────────────┘
```

##### セグメント結合

録音終了時、複数のセグメントファイルを `AVMutableComposition` で結合します：

- **セグメント数が 1 の場合**: リネームのみ（結合不要）
- **セグメント数が 2 以上の場合**: 全セグメントを時系列順に結合

##### 結合失敗時の挙動

セグメント結合に失敗した場合：

1. 最初のセグメントのみを最終ファイルとして使用
2. ダイアログで警告を表示（「録音の一部が保存されました」）
3. 文字起こし処理は続行

```swift
/// 録音停止結果
struct StopResult: Sendable, Equatable {
    let url: URL           // 最終ファイルURL
    let isPartial: Bool    // 部分的成功か（結合失敗時 true）
    let usedSegments: Int  // 使用されたセグメント数
    let totalSegments: Int // 総セグメント数
}
```

##### セグメントファイル

| 項目           | 値                                            |
| -------------- | --------------------------------------------- |
| 保存先         | `~/Library/Caches/com.whisperpad.recordings/` |
| ファイル名     | `whisperpad_{identifier}_segment{N}.wav`      |
| クリーンアップ | 録音終了時に自動削除                          |

### 4.4 文字起こし機能

#### 4.4.1 WhisperKit モデル

| モデル     | サイズ | 処理速度   | 精度  | 推奨用途                     |
| ---------- | ------ | ---------- | ----- | ---------------------------- |
| `tiny`     | ~40MB  | ⚡⚡⚡⚡⚡ | ★★☆☆☆ | 短いメモ、リアルタイム性重視 |
| `base`     | ~75MB  | ⚡⚡⚡⚡   | ★★★☆☆ | 日常的な使用                 |
| `small`    | ~250MB | ⚡⚡⚡     | ★★★★☆ | **デフォルト推奨**           |
| `medium`   | ~750MB | ⚡⚡       | ★★★★☆ | 高精度が必要な場合           |
| `large-v3` | ~1.5GB | ⚡         | ★★★★★ | 最高精度                     |

#### 4.4.2 文字起こし設定

```swift
struct TranscriptionSettings: Codable, Equatable {
    var modelName: String = "small"
    var language: TranscriptionLanguage = .auto
    var task: TranscriptionTask = .transcribe
    var suppressBlank: Bool = true
    var wordTimestamps: Bool = false

    enum TranscriptionLanguage: String, Codable, CaseIterable {
        case auto = "auto"
        case japanese = "ja"
        case english = "en"
        case chinese = "zh"
        // ... 他の言語
    }

    enum TranscriptionTask: String, Codable {
        case transcribe = "transcribe"  // 書き起こし
        case translate = "translate"    // 英語への翻訳
    }
}
```

#### 4.4.3 文字起こし状態

```swift
enum TranscriptionStatus: Equatable {
    case idle                           // 待機中
    case loading                        // モデル読み込み中
    case processing(progress: Double)   // 変換中（進捗率）
    case completed(text: String)        // 完了
    case failed(error: TranscriptionError)  // 失敗
}
```

### 4.5 出力機能

#### 4.5.1 出力先設定

| 出力先         | 説明                                     | デフォルト |
| -------------- | ---------------------------------------- | ---------- |
| クリップボード | システムクリップボードにコピー           | ON         |
| ファイル       | 指定フォルダにテキストファイルとして保存 | OFF        |
| 両方           | クリップボードとファイル両方に出力       | -          |

#### 4.5.2 ファイル出力設定

```swift
struct FileOutputSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var outputDirectory: URL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!.appendingPathComponent("WhisperPad")
    var fileNameFormat: FileNameFormat = .dateTime
    var fileExtension: FileExtension = .txt
    var includeMetadata: Bool = true

    enum FileNameFormat: String, Codable, CaseIterable {
        case dateTime = "WhisperPad_yyyyMMdd_HHmmss"
        case timestamp = "WhisperPad_timestamp"
        case sequential = "WhisperPad_001"
    }

    enum FileExtension: String, Codable, CaseIterable {
        case txt = "txt"
        case md = "md"
    }
}
```

#### 4.5.3 出力データ構造

```swift
struct TranscriptionOutput: Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let duration: TimeInterval       // 録音時間
    let text: String                 // 書き起こしテキスト
    let language: String?            // 検出された言語
    let modelUsed: String            // 使用したモデル
    let audioFilePath: URL?          // 元音声ファイル（保存時）
}
```

---

## 5. 画面仕様

### 5.1 設定画面

#### 5.1.1 設定画面構成

```
┌─────────────────────────────────────────────────────────────────┐
│ WhisperPad 設定                                            ✕    │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────┐                                                     │
│ │ 一般    │  ┌───────────────────────────────────────────────┐ │
│ ├─────────┤  │                                               │ │
│ │ ホット  │  │  【一般設定】                                 │ │
│ │ キー    │  │                                               │ │
│ ├─────────┤  │  □ ログイン時に起動                          │ │
│ │ 録音    │  │                                               │ │
│ ├─────────┤  │  □ 完了時に通知を表示                        │ │
│ │ モデル  │  │                                               │ │
│ ├─────────┤  │  □ 完了音を鳴らす                            │ │
│ │ 出力    │  │                                               │ │
│ ├─────────┤  │  メニューバーアイコン:                        │ │
│ │ 履歴    │  │  ○ 標準  ○ モノクロ  ○ カラー              │ │
│ └─────────┘  │                                               │ │
│              └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

#### 5.1.2 一般設定

| 項目             | 型   | デフォルト | 説明                                 |
| ---------------- | ---- | ---------- | ------------------------------------ |
| ログイン時に起動 | Bool | false      | macOS 起動時に自動起動               |
| 完了時に通知     | Bool | true       | 文字起こし完了時に通知センターに表示 |
| 完了音           | Bool | true       | 処理完了時にサウンド再生             |
| アイコンスタイル | Enum | standard   | メニューバーアイコンのスタイル       |

#### 5.1.3 ホットキー設定

```
┌───────────────────────────────────────────────────────────────┐
│ 【ホットキー設定】                                            │
│                                                               │
│ 録音開始/停止:                                               │
│ ┌─────────────────────────────────────┐                      │
│ │  ⌥ Option + Space        [変更]    │                      │
│ └─────────────────────────────────────┘                      │
│                                                               │
│ 録音モード:                                                   │
│ ○ トグル（1回押しで開始/停止）                               │
│ ● プッシュ・トゥ・トーク（押している間のみ録音）             │
│                                                               │
│ 最後の書き起こしをペースト:                                   │
│ ┌─────────────────────────────────────┐                      │
│ │  ⌘ Cmd + Shift + V       [変更]    │                      │
│ └─────────────────────────────────────┘                      │
│                                                               │
│ 設定を開く:                                                   │
│ ┌─────────────────────────────────────┐                      │
│ │  ⌘ Cmd + Shift + ,       [変更]    │                      │
│ └─────────────────────────────────────┘                      │
│                                                               │
│ ⚠️ 他のアプリと競合する場合は変更してください                 │
└───────────────────────────────────────────────────────────────┘
```

#### 5.1.4 録音設定

```
┌───────────────────────────────────────────────────────────────┐
│ 【録音設定】                                                  │
│                                                               │
│ 入力デバイス:                                                 │
│ ┌─────────────────────────────────────────────────┐          │
│ │  MacBook Pro マイク                         ▼   │          │
│ └─────────────────────────────────────────────────┘          │
│                                                               │
│ 最大録音時間:                                                 │
│ ├────────────────────●────────────────────────┤ 60秒        │
│ (10秒 〜 300秒)                                              │
│                                                               │
│ □ 無音検出で自動停止                                         │
│   └─ 無音判定時間: [  3  ] 秒                                │
│                                                               │
│ 入力レベル:                                                   │
│ ████████████░░░░░░░░░░░░░░░░░░░░  -12dB                      │
└───────────────────────────────────────────────────────────────┘
```

#### 5.1.5 モデル設定

```
┌───────────────────────────────────────────────────────────────┐
│ 【モデル設定】                                                │
│                                                               │
│ 使用モデル:                                                   │
│ ┌─────────────────────────────────────────────────┐          │
│ │  small (推奨)                               ▼   │          │
│ └─────────────────────────────────────────────────┘          │
│                                                               │
│ ┌─────────────────────────────────────────────────┐          │
│ │ モデル    │ サイズ   │ 速度  │ 精度  │ 状態    │          │
│ ├───────────┼──────────┼───────┼───────┼─────────┤          │
│ │ tiny      │ 40MB     │ ⚡⚡⚡⚡ │ ★★☆☆ │ [DL]    │          │
│ │ base      │ 75MB     │ ⚡⚡⚡  │ ★★★☆ │ [DL]    │          │
│ │ small     │ 250MB    │ ⚡⚡   │ ★★★★ │ ✓ 済    │          │
│ │ medium    │ 750MB    │ ⚡    │ ★★★★ │ [DL]    │          │
│ │ large-v3  │ 1.5GB    │ ⚡    │ ★★★★★│ [DL]    │          │
│ └─────────────────────────────────────────────────┘          │
│                                                               │
│ 認識言語:                                                     │
│ ○ 自動検出                                                   │
│ ○ 日本語                                                     │
│ ○ 英語                                                       │
│ ○ その他: [選択...]                                          │
│                                                               │
│ ストレージ使用量: 250MB / 5GB                                 │
│ [不要なモデルを削除...]                                       │
└───────────────────────────────────────────────────────────────┘
```

#### 5.1.6 出力設定

```
┌───────────────────────────────────────────────────────────────┐
│ 【出力設定】                                                  │
│                                                               │
│ ☑ クリップボードにコピー                                     │
│                                                               │
│ □ ファイルに保存                                             │
│   └─ 保存先: ~/Documents/WhisperPad        [変更...]          │
│   └─ ファイル名形式:                                         │
│      ○ 日時 (WhisperPad_20241201_143052.txt)                 │
│      ○ タイムスタンプ (WhisperPad_1701415852.txt)            │
│      ○ 連番 (WhisperPad_001.txt)                             │
│   └─ ファイル形式:                                           │
│      ○ テキスト (.txt)                                      │
│      ○ マークダウン (.md)                                   │
│                                                               │
│ □ メタデータを含める                                         │
│   (録音日時、使用モデル、言語など)                           │
│                                                               │
│ □ 元の音声ファイルも保存                                     │
└───────────────────────────────────────────────────────────────┘
```

### 5.2 履歴画面

```
┌───────────────────────────────────────────────────────────────┐
│ 履歴                                              ✕           │
├───────────────────────────────────────────────────────────────┤
│ 🔍 [検索...]                             [今日 ▼] [すべて消去]│
├───────────────────────────────────────────────────────────────┤
│                                                               │
│ ■ 今日                                                       │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ 14:30  1分30秒  small  日本語                           │  │
│ │ 今日の会議では来期の予算について話し合いました。主な議...  │  │
│ │                                    [コピー] [削除] [...]  │  │
│ └─────────────────────────────────────────────────────────┘  │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ 10:15  45秒  small  日本語                              │  │
│ │ 新しいアプリのアイデア：音声でメモを取れるツール...       │  │
│ │                                    [コピー] [削除] [...]  │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                               │
│ ■ 昨日                                                       │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ 18:45  2分15秒  small  英語                             │  │
│ │ The meeting discussed several key points about...        │  │
│ │                                    [コピー] [削除] [...]  │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                               │
│                         [もっと読み込む...]                   │
└───────────────────────────────────────────────────────────────┘
```

---

## 6. 状態遷移

### 6.1 アプリケーション状態遷移図

```
                              ┌─────────────────┐
                              │    App起動      │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  モデル確認     │
                              └────────┬────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │                           │
                         ▼                           ▼
              ┌─────────────────┐         ┌─────────────────┐
              │ モデルあり      │         │ モデルなし      │
              └────────┬────────┘         └────────┬────────┘
                       │                           │
                       │                           ▼
                       │                  ┌─────────────────┐
                       │                  │ ダウンロード    │
                       │                  │ プロンプト表示  │
                       │                  └────────┬────────┘
                       │                           │
                       │◀──────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │     Idle        │◀─────────────────────────────┐
              │   （待機中）     │                              │
              └────────┬────────┘                              │
                       │                                       │
                       │ ホットキー押下                        │
                       ▼                                       │
              ┌─────────────────┐◀───────────────────────────────┐
              │   Recording     │                              ││
              │  （録音中）      │                              ││
              └────────┬────────┘                              ││
                       │                                       ││再開
         ┌─────────────┼─────────────┬─────────────────────────┤│
         │             │             │                        ││
         ▼             ▼             ▼                        ▼│
   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
   │ホットキー │ │最大時間  │ │  Escape  │ │  一時停止    │   │
   │  再押下   │ │  到達    │ │   押下   │ │    押下      │   │
   └─────┬────┘ └─────┬────┘ └─────┬────┘ └───────┬──────┘   │
         │            │            │              │          │
         │            │            │              ▼          │
         │            │            │        ┌──────────┐     │
         │            │            │        │  Paused  │─────┘
         │            │            │        │(一時停止)│
         │            │            │        └────┬─────┘
         ▼            ▼            │◀────────────┘終了
   ┌─────────────────────┐         │                          │
   │   Transcribing      │         │                          │
   │  （文字起こし中）    │         │                          │
   └──────────┬──────────┘         │                          │
              │                    │                          │
    ┌─────────┴─────────┐          │                          │
    │                   │          │                          │
    ▼                   ▼          │                          │
┌────────┐        ┌────────┐       │                          │
│ 成功   │        │ 失敗   │       │                          │
└───┬────┘        └───┬────┘       │                          │
    │                 │            │                          │
    ▼                 ▼            │                          │
┌────────────┐  ┌────────────┐     │                          │
│ Completed  │  │  Error     │     │                          │
│ （完了）    │  │（エラー）  │     │                          │
└─────┬──────┘  └─────┬──────┘     │                          │
      │               │            │                          │
      │ 出力処理      │            │ キャンセル               │
      ▼               ▼            ▼                          │
┌─────────────────────────────────────────────┐               │
│              3秒後に自動遷移                 │───────────────┘
└─────────────────────────────────────────────┘
```

### 6.2 状態定義

```swift
@ObservableState
struct AppState: Equatable {
    var appStatus: AppStatus = .idle
    var recording: RecordingFeature.State = .init()
    var transcription: TranscriptionFeature.State = .init()
    var settings: SettingsFeature.State = .init()
    var history: HistoryFeature.State = .init()
    var lastTranscription: TranscriptionOutput?
    var errorMessage: String?
}

enum AppStatus: Equatable {
    case idle                                   // 待機中
    case recording(duration: TimeInterval)      // 録音中
    case paused(duration: TimeInterval)         // 一時停止中
    case transcribing(progress: Double)         // 文字起こし中
    case completed                              // 完了
    case error(message: String)                 // エラー
}
```

### 6.3 メニューバーアイコン状態

| AppStatus       | アイコン                   | 色           | アニメーション           |
| --------------- | -------------------------- | ------------ | ------------------------ |
| `.idle`         | `mic`                      | systemGray   | なし                     |
| `.recording`    | `mic.fill`                 | systemRed    | パルス（波形）           |
| `.paused`       | `pause.circle`             | systemOrange | なし                     |
| `.transcribing` | `gear`                     | systemBlue   | 回転                     |
| `.completed`    | `checkmark.circle`         | systemGreen  | なし（3 秒後に idle へ） |
| `.error`        | `exclamationmark.triangle` | systemYellow | なし                     |

---

## 7. データ仕様

### 7.1 永続化データ

#### 7.1.1 UserDefaults キー

| キー                                | 型          | 説明                   |
| ----------------------------------- | ----------- | ---------------------- |
| `WhisperPad.settings.general`       | Data (JSON) | 一般設定               |
| `WhisperPad.settings.hotkey`        | Data (JSON) | ホットキー設定         |
| `WhisperPad.settings.recording`     | Data (JSON) | 録音設定               |
| `WhisperPad.settings.transcription` | Data (JSON) | 文字起こし設定         |
| `WhisperPad.settings.output`        | Data (JSON) | 出力設定               |
| `WhisperPad.lastModelUsed`          | String      | 最後に使用したモデル名 |

#### 7.1.2 設定モデル（完全版）

```swift
struct AppSettings: Codable, Equatable {
    var general: GeneralSettings
    var hotKey: HotKeySettings
    var recording: RecordingSettings
    var transcription: TranscriptionSettings
    var output: OutputSettings

    static let `default` = AppSettings(
        general: .default,
        hotKey: .default,
        recording: .default,
        transcription: .default,
        output: .default
    )
}

struct GeneralSettings: Codable, Equatable {
    var launchAtLogin: Bool = false
    var showNotificationOnComplete: Bool = true
    var playSoundOnComplete: Bool = true
    var menuBarIconStyle: MenuBarIconStyle = .standard

    enum MenuBarIconStyle: String, Codable, CaseIterable {
        case standard
        case monochrome
        case colorful
    }

    static let `default` = GeneralSettings()
}

struct RecordingSettings: Codable, Equatable {
    var inputDeviceID: String?  // nil = システムデフォルト
    var maxDuration: TimeInterval = 60
    var silenceDetectionEnabled: Bool = false
    var silenceThreshold: Float = -40  // dB
    var silenceDuration: TimeInterval = 3

    static let `default` = RecordingSettings()
}

struct OutputSettings: Codable, Equatable {
    var copyToClipboard: Bool = true
    var fileOutput: FileOutputSettings = .init()
    var saveOriginalAudio: Bool = false

    static let `default` = OutputSettings()
}
```

### 7.2 履歴データ

#### 7.2.1 履歴保存先

```
~/Library/Application Support/WhisperPad/
├── history.json                    # 履歴メタデータ
├── transcriptions/
│   ├── {uuid}.txt                  # 書き起こしテキスト
│   └── {uuid}.wav                  # 元音声（オプション）
└── models/
    └── {model_name}/               # WhisperKitモデル
```

#### 7.2.2 履歴データモデル

```swift
struct TranscriptionHistory: Codable, Equatable {
    var items: [TranscriptionHistoryItem]
    var totalCount: Int
    var lastUpdated: Date
}

struct TranscriptionHistoryItem: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let duration: TimeInterval
    let text: String
    let language: String?
    let modelUsed: String
    let textFilePath: String?
    let audioFilePath: String?

    var preview: String {
        String(text.prefix(100))
    }
}
```

### 7.3 一時データ

| データ           | 保存先                         | 寿命           |
| ---------------- | ------------------------------ | -------------- |
| 録音中音声       | `NSTemporaryDirectory()`       | 処理完了まで   |
| モデルキャッシュ | `~/Library/Caches/WhisperPad/` | 明示的削除まで |

---

## 8. 外部ライブラリ

### 8.1 依存ライブラリ一覧

| ライブラリ                                                          | バージョン | 用途                 | ライセンス |
| ------------------------------------------------------------------- | ---------- | -------------------- | ---------- |
| [WhisperKit](https://github.com/argmaxinc/WhisperKit)               | 0.15.0+    | 音声認識             | MIT        |
| [TCA](https://github.com/pointfreeco/swift-composable-architecture) | 1.23.1+    | 状態管理             | MIT        |
| [HotKey](https://github.com/soffes/HotKey)                          | 0.2.1+     | グローバルホットキー | MIT        |

### 8.2 Package.swift

```swift
// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WhisperPad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhisperPad", targets: ["WhisperPad"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/WhisperKit.git",
            from: "0.15.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.23.1"
        ),
        .package(
            url: "https://github.com/soffes/HotKey.git",
            from: "0.2.1"
        ),
    ],
    targets: [
        .executableTarget(
            name: "WhisperPad",
            dependencies: [
                "WhisperKit",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                "HotKey",
            ]
        ),
        .testTarget(
            name: "WhisperPadTests",
            dependencies: [
                "WhisperPad",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ]
        ),
    ]
)
```

---

## 9. セキュリティ・プライバシー

### 9.1 プライバシーポリシー

| 項目               | 対応                             |
| ------------------ | -------------------------------- |
| 音声データの送信   | **なし**（完全オンデバイス処理） |
| テレメトリ         | **なし**                         |
| クラウド同期       | **なし**                         |
| サードパーティ共有 | **なし**                         |

### 9.2 必要な権限と用途

| 権限             | 用途                 | 拒否時の動作                           |
| ---------------- | -------------------- | -------------------------------------- |
| マイクアクセス   | 音声録音             | 録音機能無効化、設定を促すアラート表示 |
| アクセシビリティ | グローバルホットキー | メニューバーからの手動操作のみ可能     |

### 9.3 Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

### 9.4 Info.plist 権限説明

```xml
<key>NSMicrophoneUsageDescription</key>
<string>WhisperPadは音声をテキストに変換するためにマイクを使用します。音声データはデバイス上でのみ処理され、外部に送信されることはありません。</string>
```

---

## 10. エラーハンドリング

### 10.1 エラー種別

```swift
enum WhisperPadError: Error, Equatable, LocalizedError {
    // 権限エラー
    case microphonePermissionDenied
    case accessibilityPermissionDenied

    // 録音エラー
    case audioSessionSetupFailed(String)
    case recordingFailed(String)
    case noAudioInput

    // 文字起こしエラー
    case modelNotFound(String)
    case modelDownloadFailed(String)
    case transcriptionFailed(String)
    case transcriptionTimeout

    // 出力エラー
    case clipboardWriteFailed
    case fileWriteFailed(String)
    case directoryCreateFailed(String)

    // その他
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "マイクへのアクセスが許可されていません"
        case .accessibilityPermissionDenied:
            return "アクセシビリティ権限が許可されていません"
        // ... 他のケース
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "システム環境設定 > プライバシーとセキュリティ > マイク で WhisperPad を許可してください"
        // ... 他のケース
        }
    }
}
```

### 10.2 エラー表示

| エラー種別       | 表示方法                            | 自動消去 |
| ---------------- | ----------------------------------- | -------- |
| 権限エラー       | アラートダイアログ + 設定へのリンク | 手動     |
| 録音エラー       | メニューバー + 通知                 | 5 秒     |
| 文字起こしエラー | メニューバー + 通知                 | 5 秒     |
| 出力エラー       | 通知                                | 5 秒     |

### 10.3 リカバリー処理

```swift
enum ErrorRecoveryAction {
    case openSystemPreferences(PrivacyPane)
    case retryOperation
    case downloadModel(String)
    case selectAlternativeOutput
    case dismiss

    enum PrivacyPane {
        case microphone
        case accessibility
    }
}
```

---

## 11. テスト仕様

### 11.1 ユニットテスト

| テスト対象           | テスト内容                                   |
| -------------------- | -------------------------------------------- |
| RecordingFeature     | 状態遷移、録音開始/停止アクション            |
| TranscriptionFeature | モデル読み込み、変換処理、エラーハンドリング |
| SettingsFeature      | 設定の読み込み/保存、バリデーション          |
| HistoryFeature       | 履歴の追加/削除/検索                         |
| OutputClient         | クリップボード/ファイル出力                  |

### 11.2 統合テスト

| テストケース                           | 期待結果                                |
| -------------------------------------- | --------------------------------------- |
| 録音 → 文字起こし → クリップボード出力 | テキストがクリップボードにコピーされる  |
| 録音 → 文字起こし → ファイル出力       | 指定フォルダにファイルが作成される      |
| 録音キャンセル                         | 一時ファイルが削除され、idle 状態に戻る |
| 設定変更 → アプリ再起動                | 設定が永続化されている                  |

### 11.3 UI テスト

| テストケース         | 確認項目                     |
| -------------------- | ---------------------------- |
| メニューバークリック | メニューが表示される         |
| 設定画面表示         | 各タブが正常に切り替わる     |
| ホットキー入力       | キーコンボが正しく記録される |

---

## 12. 今後の拡張予定

### 12.1 ロードマップ

| バージョン | 機能                            | 優先度 |
| ---------- | ------------------------------- | ------ |
| v0.2.0     | リアルタイムプレビュー          | 高     |
| v0.2.0     | カスタムプロンプト（用語集）    | 高     |
| v0.3.0     | 話者分離（Speaker Diarization） | 中     |
| v0.3.0     | ショートカットアプリ連携        | 中     |
| v0.4.0     | 翻訳機能強化                    | 低     |
| v0.4.0     | Obsidian/Notion 連携            | 低     |

### 12.2 検討中の機能

- Apple Watch 連携（リモート録音開始）
- iPhone/iPad 版
- 音声コマンド（「録音開始」「録音終了」）
- 自動要約機能（LLM 連携）
- タグ・フォルダによる整理機能

---

_本仕様書は開発の進行に応じて更新されます。_
