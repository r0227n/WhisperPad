# VoiceSnap 開発タスクリスト

> Swift/SwiftUI 初学者向け。各タスクは半日〜1 日程度で完了できる想定。

---

## Phase 0: 環境・基盤整備 🔀 **並行開発可能**

> この Phase のタスクは互いに依存しないため、`git worktree`で並行作業可能です。

### 0-1. プロジェクト基盤整備

**目的**: Git 管理とアプリ権限の基盤を整備

**作業内容**:

1. **`.gitignore`作成**

   - プロジェクトルートに`.gitignore`を作成
   - macOS、Xcode、Swift 関連の除外パターンを追加
   - 参考: [github/gitignore - Swift.gitignore](https://github.com/github/gitignore/blob/main/Swift.gitignore)

2. **`Entitlements`設定**

   - `WhisperPad/WhisperPad/WhisperPad.entitlements`を新規作成
   - App Sandbox、マイクアクセス、ファイルアクセス権限を追加
   - Xcode でターゲットに紐付け

3. **`Info.plist`権限説明追加**
   - `NSMicrophoneUsageDescription`を追加
   - マイク使用時にユーザーに表示する説明文を設定

**対象ファイル**:

- `.gitignore`（新規）
- `WhisperPad/WhisperPad/WhisperPad.entitlements`（新規）
- `WhisperPad/WhisperPad/Info.plist`（新規または編集）

**完了条件**:

- [ ] `.gitignore`ファイルが存在し、`git status`で不要ファイルが表示されない
- [ ] Entitlements ファイルが存在し、Xcode でターゲットに紐付けられている
- [ ] Info.plist にマイク使用説明が記載されている
- [ ] ビルドが通る

**追加する権限（Entitlements）**:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

---

### 0-2. アセット・アイコン設定

**目的**: アプリアイコンとメニューバー用アイコンを設定

**作業内容**:

1. **AppIcon 設定**

   - `Assets.xcassets/AppIcon.appiconset/`にアイコンを追加
   - 必要なサイズ: 16x16, 32x32, 128x128, 256x256, 512x512（@1x, @2x）

2. **メニューバーアイコン準備**
   - SF Symbols（`mic`, `mic.fill`等）を使用予定であることを確認
   - カスタムアイコンが必要な場合は`Assets.xcassets`に追加

**対象ファイル**:

- `WhisperPad/WhisperPad/Assets.xcassets/AppIcon.appiconset/`

**完了条件**:

- [ ] アプリアイコンが設定されている
- [ ] ビルド後、Finder でアイコンが表示される

**備考**: 初期段階ではプレースホルダーアイコンでも可。SF Symbols を使用する場合はコードで指定するため、この段階では AppIcon のみで十分。

---

### 0-3. Package.swift 作成

**目的**: Swift Package Manager 対応のパッケージ定義を作成

**学習ポイント**:

- Swift Package Manager（SPM）の基本構造
- 依存関係の定義方法
- `Package.swift`と`.xcodeproj`の関係

**作業内容**:

1. **`Package.swift`の作成**

   - プロジェクトルートに`Package.swift`を作成
   - 必要な依存関係を定義（WhisperKit, TCA, HotKey）
   - macOS 14.0 以降をターゲットに設定

2. **依存関係の確認**
   - `swift package resolve`でパッケージが解決できることを確認

**対象ファイル**:

- `Package.swift`（新規）

**完了条件**:

- [ ] `Package.swift`が存在する
- [ ] `swift package resolve`が成功する
- [ ] 定義されたパッケージが正しくダウンロードされる

**Package.swift 例**:

```swift
// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VoiceSnap",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoiceSnap", targets: ["VoiceSnap"])
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
            name: "VoiceSnap",
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
            name: "VoiceSnapTests",
            dependencies: [
                "VoiceSnap",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ]
        ),
    ]
)
```

**注意**: Xcode プロジェクト（`.xcodeproj`）との併用方法を検討すること。SPM のみで管理するか、Xcode プロジェクトと併用するかを決定する。

---

## Phase 1: メニューバーアプリ基礎 📱

> SwiftUI/AppKit の基礎を学びながら、メニューバーアプリの骨格を作成

### 1-1. メニューバーアプリ化

**目的**: Dock に表示されないメニューバー常駐アプリを実装

**学習ポイント**:

- `LSUIElement`の理解（Dock に表示しない設定）
- `@NSApplicationDelegateAdaptor`の使い方
- `NSStatusItem`と`NSMenu`の基礎
- SwiftUI から AppKit へのブリッジ

**作業内容**:

1. **メニューバー専用アプリ化**

   - Info.plist に`LSUIElement = true`を追加
   - `WhisperPadApp.swift`から`WindowGroup`を削除

2. **AppDelegate 導入**

   - `App/AppDelegate.swift`を新規作成
   - `NSStatusItem`でメニューバーにアイコンを表示
   - `WhisperPadApp.swift`で`@NSApplicationDelegateAdaptor`を使用

3. **基本メニュー実装**
   - メニュー項目を追加（録音開始、設定、終了）
   - 「終了」クリックで`NSApp.terminate`を呼び出す

**対象ファイル**:

- `Info.plist`（修正）
- `WhisperPad/WhisperPad/WhisperPadApp.swift`（修正）
- `WhisperPad/WhisperPad/App/AppDelegate.swift`（新規）

**完了条件**:

- [ ] アプリ起動時に Dock にアイコンが表示されない
- [ ] メニューバーにマイクアイコン（SF Symbol: `mic`）が表示される
- [ ] アイコンクリックでメニューが表示される
- [ ] 「終了」クリックでアプリが終了する

**動作確認**:

1. `Cmd + R`でアプリ実行
2. Dock にアイコンがないことを確認
3. メニューバー右側にマイクアイコンが表示されることを確認
4. クリックでメニューが開き、「終了」で終了することを確認

**メニュー構成（この段階）**:

```
┌─────────────────────┐
│ 🎤 録音開始         │  ← 無効状態（グレーアウト）
├─────────────────────┤
│ ⚙️ 設定...          │  ← 無効状態
├─────────────────────┤
│ 終了                │  ← 動作する
└─────────────────────┘
```

---

### 1-2. プロジェクト整理

**目的**: 不要なファイルを削除し、フォルダ構造を整備

**作業内容**:

1. **不要ファイル削除**

   - `ContentView.swift`を削除
   - 関連する参照を削除

2. **フォルダ構造作成**
   - `App/`フォルダを作成（AppDelegate.swift, AppReducer.swift 用）
   - `Features/`フォルダを作成（Recording, Transcription, Settings 用）
   - `Clients/`フォルダを作成（AudioRecorderClient 等用）
   - `Models/`フォルダを作成

**対象ファイル**:

- `ContentView.swift`（削除）
- 各フォルダ（新規作成）

**完了条件**:

- [ ] `ContentView.swift`が存在しない
- [ ] フォルダ構造が整備されている
- [ ] ビルドが通る
- [ ] アプリが正常に起動する

---

## Phase 2: TCA 導入・状態管理 🏗️

> The Composable Architecture を導入し、状態管理の基礎を学ぶ

### 2-1. TCA 導入と AppReducer 実装

**目的**: TCA をプロジェクトに導入し、アプリ全体の状態管理を実装

**学習ポイント**:

- Xcode での SPM パッケージ管理
- TCA の`@Reducer`マクロ
- `State`と`Action`の定義
- `Store`の作成と保持

**作業内容**:

1. **TCA パッケージ追加**

   - Xcode で`swift-composable-architecture`パッケージを追加
   - URL: `https://github.com/pointfreeco/swift-composable-architecture`
   - バージョン: `1.23.0`以上

2. **AppReducer 実装**

   - `App/AppReducer.swift`を新規作成
   - `AppStatus`（idle, recording, transcribing, completed, error）を定義
   - 基本的なアクション（startRecording, stopRecording 等）を定義

3. **Store 統合**
   - `AppDelegate`で`Store`を作成
   - アプリ起動時に Store が初期化されるようにする

**対象ファイル**:

- `WhisperPad/WhisperPad/App/AppReducer.swift`（新規）
- `WhisperPad/WhisperPad/App/AppDelegate.swift`（修正）

**完了条件**:

- [ ] パッケージが正常にダウンロードされる
- [ ] `import ComposableArchitecture`でエラーが出ない
- [ ] `AppReducer`が作成されている
- [ ] `Store`がアプリ起動時に作成される
- [ ] ビルドが通る

**コード例（AppReducer.swift）**:

```swift
import ComposableArchitecture

@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        var appStatus: AppStatus = .idle
    }

    enum AppStatus: Equatable {
        case idle
        case recording
        case transcribing
        case completed
        case error(String)
    }

    enum Action {
        case startRecording
        case stopRecording
        case transcriptionCompleted(String)
        case errorOccurred(String)
        case resetToIdle
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startRecording:
                state.appStatus = .recording
                return .none
            case .stopRecording:
                state.appStatus = .transcribing
                return .none
            case .transcriptionCompleted:
                state.appStatus = .completed
                return .none
            case .errorOccurred(let message):
                state.appStatus = .error(message)
                return .none
            case .resetToIdle:
                state.appStatus = .idle
                return .none
            }
        }
    }
}
```

---

### 2-2. メニューと状態の連携

**目的**: AppStatus に応じてメニュー項目とアイコンを動的に更新

**学習ポイント**:

- TCA の状態監視（`observe`）
- UI の動的更新
- `NSStatusItem`のアイコン変更

**作業内容**:

1. **メニュー項目の動的更新**

   - `appStatus`に応じてメニュー項目のタイトルを変更
     - idle: 「録音開始」
     - recording: 「録音停止」
     - transcribing: 「文字起こし中...」（無効）
   - メニュー項目のアクションを Store と連携

2. **アイコンの動的更新**

   - idle: `mic`（グレー）
   - recording: `mic.fill`（赤）
   - transcribing: `gear`（回転アニメーション）
   - completed: `checkmark.circle`（緑、3 秒後に idle へ）
   - error: `exclamationmark.triangle`（黄）

3. **デバッグ用状態変更**
   - メニューから状態を変更できるようにする（動作確認用）

**対象ファイル**:

- `AppDelegate.swift`（修正）

**完了条件**:

- [ ] 状態によってメニュー項目のタイトルが変化する
- [ ] 状態によってメニューバーアイコンが変化する
- [ ] デバッグ用に状態を手動で変更できる

---

## Phase 3: 録音機能 🎙️

> AVFoundation を使用した音声録音機能の実装

### 3-1. 録音機能基盤

**目的**: 録音機能の基盤となる Feature と Client を実装

**学習ポイント**:

- TCA の Feature 分割
- TCA の`DependencyKey`パターン
- `AVCaptureDevice.requestAccess`の使用
- `AVAudioRecorder`の基本

**作業内容**:

1. **RecordingFeature 作成**

   - `Features/Recording/RecordingFeature.swift`を新規作成
   - 録音状態（idle, preparing, recording, stopping）を定義
   - AppReducer に子 Reducer として統合

2. **マイク権限要求**

   - 権限要求ロジックを実装
   - 権限拒否時のハンドリング

3. **AudioRecorderClient 実装**
   - `Clients/AudioRecorderClient.swift`を新規作成
   - 録音開始/停止メソッドを実装
   - 録音設定（16kHz, モノラル, WAV）を適用

**対象ファイル**:

- `WhisperPad/WhisperPad/Features/Recording/RecordingFeature.swift`（新規）
- `WhisperPad/WhisperPad/Clients/AudioRecorderClient.swift`（新規）
- `AppReducer.swift`（修正）

**完了条件**:

- [ ] RecordingFeature が作成され AppReducer に統合されている
- [ ] マイク権限ダイアログが表示される
- [ ] AudioRecorderClient で録音開始/停止ができる
- [ ] 一時ディレクトリに`.wav`ファイルが生成される

**録音設定**:

```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVSampleRateKey: 16000,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

---

### 3-2. 録音 UI と動作確認

**目的**: メニューから録音を操作し、完全な録音フローを実現

**作業内容**:

1. **メニューとの連携**

   - 「録音開始」クリックで録音開始
   - 「録音停止」クリックで録音停止
   - 録音中はメニューバーアイコンを赤に変更

2. **録音時間表示**

   - 録音中の経過時間をメニューに表示（オプション）

3. **動作確認**
   - 録音 → 停止 → ファイル生成の一連の流れを確認
   - 生成された音声ファイルを再生して品質確認

**対象ファイル**:

- `AppDelegate.swift`（修正）
- `RecordingFeature.swift`（修正）

**完了条件**:

- [ ] メニューから録音開始/停止ができる
- [ ] 録音中はアイコンが赤く変わる
- [ ] 録音停止後、音声ファイルが生成される
- [ ] 生成されたファイルが再生可能

---

## Phase 4: WhisperKit 統合 🤖

> オンデバイス音声認識の実装

### 4-1. WhisperKit 導入

**目的**: WhisperKit をプロジェクトに導入し、モデル管理機能を実装

**学習ポイント**:

- WhisperKit の基本的な使い方
- 非同期処理（async/await）
- モデルのダウンロードと管理

**作業内容**:

1. **WhisperKit パッケージ追加**

   - Xcode で WhisperKit パッケージを追加
   - URL: `https://github.com/argmaxinc/WhisperKit`
   - バージョン: `0.9.0`以上

2. **TranscriptionClient 基本実装**

   - `Clients/TranscriptionClient.swift`を新規作成
   - WhisperKit の初期化
   - モデル一覧取得
   - モデルダウンロード機能

3. **モデルダウンロード動作確認**
   - `tiny`モデルのダウンロードを実行
   - ダウンロード完了をログで確認

**対象ファイル**:

- `WhisperPad/WhisperPad/Clients/TranscriptionClient.swift`（新規）

**完了条件**:

- [ ] パッケージが正常にダウンロードされる
- [ ] `import WhisperKit`でエラーが出ない
- [ ] WhisperKit が初期化できる
- [ ] `tiny`モデルがダウンロードできる

**注意**: WhisperKit は大きなパッケージのため、ダウンロードに時間がかかる場合があります。

---

### 4-2. 文字起こし実行

**目的**: 録音した音声を文字に変換する機能を実装

**作業内容**:

1. **TranscriptionFeature 作成**

   - `Features/Transcription/TranscriptionFeature.swift`を新規作成
   - 文字起こし状態（idle, loading, processing, completed, failed）を定義

2. **文字起こし実行**

   - 録音停止後に自動で文字起こしを開始
   - WhisperKit での音声認識を実行
   - 結果をコンソールに出力

3. **録音 → 文字起こしの連携**
   - RecordingFeature と TranscriptionFeature の連携
   - 状態遷移: recording → transcribing → completed

**対象ファイル**:

- `WhisperPad/WhisperPad/Features/Transcription/TranscriptionFeature.swift`（新規）
- `AppReducer.swift`（修正）

**完了条件**:

- [ ] TranscriptionFeature が作成されている
- [ ] 録音停止後、自動で文字起こしが開始される
- [ ] 文字起こし結果がコンソールに表示される
- [ ] 状態遷移が正しく動作する

---

## Phase 5: 出力・設定 📤

> クリップボード出力と設定画面の実装

### 5-1. 出力機能

**目的**: 文字起こし結果をクリップボードに出力し、完了を通知

**学習ポイント**:

- `NSPasteboard`の使用
- `UNUserNotificationCenter`の使用
- システムサウンド再生

**作業内容**:

1. **クリップボード出力**

   - `Clients/OutputClient.swift`を新規作成
   - `NSPasteboard`でクリップボードにコピー

2. **完了通知**

   - macOS 通知センターへの通知送信
   - サウンド再生（`NSSound`）

3. **自動出力連携**
   - 文字起こし完了後、自動でクリップボードにコピー
   - 通知を表示

**対象ファイル**:

- `WhisperPad/WhisperPad/Clients/OutputClient.swift`（新規）
- `TranscriptionFeature.swift`（修正）

**完了条件**:

- [ ] 文字起こし完了後、結果がクリップボードにコピーされる
- [ ] 他のアプリで`Cmd+V`でペーストできる
- [ ] 完了時に通知が表示される
- [ ] 完了音が鳴る

---

### 5-2. 設定画面と永続化

**目的**: 設定画面を実装し、設定値を永続化

**学習ポイント**:

- SwiftUI での`Settings`シーン
- `@AppStorage`と`UserDefaults`
- TCA での UserDefaults 連携

**作業内容**:

1. **設定画面基本**

   - `Features/Settings/SettingsView.swift`を新規作成
   - メニューの「設定」から開けるようにする
   - 基本的な設定項目 UI（完了通知 ON/OFF 等）

2. **SettingsFeature 実装**

   - `Features/Settings/SettingsFeature.swift`を新規作成
   - 設定状態の管理

3. **設定の永続化**
   - `Clients/UserDefaultsClient.swift`を新規作成
   - 設定値の保存/読み込み

**対象ファイル**:

- `WhisperPad/WhisperPad/Features/Settings/SettingsView.swift`（新規）
- `WhisperPad/WhisperPad/Features/Settings/SettingsFeature.swift`（新規）
- `WhisperPad/WhisperPad/Clients/UserDefaultsClient.swift`（新規）
- `WhisperPadApp.swift`（修正）

**完了条件**:

- [ ] メニューの「設定」クリックで設定ウィンドウが開く
- [ ] 設定項目が表示される
- [ ] 設定変更がアプリ再起動後も維持される

---

## Phase 6: ホットキー・仕上げ ⌨️

> グローバルホットキーとエラーハンドリングの実装

### 6-1. ホットキー機能

**目的**: グローバルホットキーで録音を開始/停止できるようにする

**学習ポイント**:

- HotKey ライブラリの使用
- グローバルイベント監視

**作業内容**:

1. **HotKey パッケージ追加**

   - Xcode で HotKey パッケージを追加
   - URL: `https://github.com/soffes/HotKey`
   - バージョン: `0.2.0`以上

2. **HotKeyClient 実装**
   - `Clients/HotKeyClient.swift`を新規作成
   - デフォルトホットキー（Option + Space）の登録
   - ホットキー押下時のアクション連携

**対象ファイル**:

- `WhisperPad/WhisperPad/Clients/HotKeyClient.swift`（新規）
- `AppDelegate.swift`（修正）

**完了条件**:

- [ ] パッケージが正常にダウンロードされる
- [ ] `import HotKey`でエラーが出ない
- [ ] `Option + Space`で録音開始/停止ができる
- [ ] 他のアプリがアクティブでも動作する

---

### 6-2. エラーハンドリングと仕上げ

**目的**: エラー処理を整備し、ログイン時起動機能を追加

**学習ポイント**:

- Swift のエラーハンドリング
- `SMAppService`の使用（macOS 13+）

**作業内容**:

1. **エラーハンドリング**

   - `Models/VoiceSnapError.swift`を新規作成
   - エラー種別の定義
   - エラー時のアラート表示
   - メニューバーアイコンの変化

2. **ログイン時起動**

   - 設定画面に「ログイン時に起動」オプションを追加
   - `SMAppService`での登録/解除

3. **仕上げ**
   - 各機能の動作確認
   - バグ修正
   - コードの整理

**対象ファイル**:

- `WhisperPad/WhisperPad/Models/VoiceSnapError.swift`（新規）
- `SettingsView.swift`（修正）
- 各 Feature（エラーハンドリング追加）

**完了条件**:

- [ ] マイク権限エラー時にアラートが表示される
- [ ] 文字起こしエラー時にメニューバーアイコンが変化する
- [ ] 設定でログイン時起動を ON/OFF できる
- [ ] macOS 再起動後、設定通りに動作する

---

## 補足情報

### フォルダ構成（最終形）

```
WhisperPad/
├── App/
│   ├── WhisperPadApp.swift
│   ├── AppDelegate.swift
│   └── AppReducer.swift
├── Features/
│   ├── Recording/
│   │   └── RecordingFeature.swift
│   ├── Transcription/
│   │   └── TranscriptionFeature.swift
│   └── Settings/
│       ├── SettingsFeature.swift
│       └── SettingsView.swift
├── Clients/
│   ├── AudioRecorderClient.swift
│   ├── TranscriptionClient.swift
│   ├── HotKeyClient.swift
│   ├── OutputClient.swift
│   └── UserDefaultsClient.swift
├── Models/
│   └── VoiceSnapError.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

### git worktree の使い方

Phase 0 のタスクを並行開発する場合：

```bash
# ブランチを作成
git branch feature/project-foundation
git branch feature/assets
git branch feature/package-swift

# worktreeを作成
git worktree add ../WhisperPad-foundation feature/project-foundation
git worktree add ../WhisperPad-assets feature/assets
git worktree add ../WhisperPad-package feature/package-swift

# 各ディレクトリで作業後、PRを作成してマージ
```

### 参考リソース

- [SwiftUI 公式ドキュメント](https://developer.apple.com/documentation/swiftui)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit)
- [HotKey](https://github.com/soffes/HotKey)
- [github/gitignore - Swift.gitignore](https://github.com/github/gitignore/blob/main/Swift.gitignore)

---

_最終更新: 2024 年 12 月_
