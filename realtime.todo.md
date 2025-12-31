# WhisperPad リアルタイム文字起こし機能 実装タスク

> **仕様書**: docs/spec.md セクション 4.6, 5.3, 6.2-6.3, 7.1, 10.1
> **ホットキー**: `⌘⇧R` でストリーミング開始
> **UI**: メニューバー直下に 400×300 ポップアップ（NSPanel）
> **参考**: WhisperKit の `AudioProcessor.startRecordingLive()` + `TranscriptionCallback`

---

## フェーズ 1: 基盤モデル（順次実行 - 最初に完了必須）

### ブランチ: feature/streaming-models

- [ ] 1.1 StreamingSettings モデル作成
  - **ファイル**: `WhisperPad/WhisperPad/Models/StreamingSettings.swift`
  - **内容**:
    ```swift
    struct StreamingSettings: Codable, Equatable, Sendable {
        var modelName: String? = nil
        var transcriptionInterval: Double = 1.0
        var confirmationCount: Int = 2
        var silenceThreshold: Float = 0.3
        var showDecodingPreview: Bool = true
        var language: String? = "ja"
        static let `default` = StreamingSettings()
    }
    ```
  - **仕様**: docs/spec.md 4.6.8, 7.1.2
  - **完了条件**: コンパイル成功、`Codable` でのエンコード/デコードが動作
  - **前提条件**: なし

- [ ] 1.2 StreamingStatus enum 作成
  - **ファイル**: `WhisperPad/WhisperPad/Models/StreamingStatus.swift`
  - **内容**:
    ```swift
    enum StreamingStatus: Equatable, Sendable {
        case idle
        case initializing
        case recording(duration: TimeInterval, tokensPerSecond: Double)
        case processing
        case completed(text: String)
        case error(String)
    }
    ```
  - **仕様**: docs/spec.md 4.6.6
  - **完了条件**: コンパイル成功
  - **前提条件**: なし

- [ ] 1.3 StreamingTranscriptionError enum 作成
  - **ファイル**: `WhisperPad/WhisperPad/Models/StreamingTranscriptionError.swift`
  - **内容**:

    ```swift
    enum StreamingTranscriptionError: Error, Equatable, Sendable, LocalizedError {
        case initializationFailed(String)
        case processingFailed(String)
        case bufferOverflow
        case microphonePermissionDenied

        var errorDescription: String? { /* ... */ }
    }
    ```

  - **仕様**: docs/spec.md 10.1
  - **完了条件**: コンパイル成功、`LocalizedError` の `errorDescription` 実装
  - **前提条件**: なし

- [ ] 1.4 AppSettings 更新
  - **ファイル**: `WhisperPad/WhisperPad/Models/AppSettings.swift`
  - **変更**:
    - `var streaming: StreamingSettings = .default` プロパティ追加
  - **完了条件**: 既存テストがパス、新しいプロパティが `Codable` で正しく処理される
  - **前提条件**: 1.1 完了

- [ ] 1.5 AppStatus 拡張
  - **ファイル**: `WhisperPad/WhisperPad/Models/AppState.swift` または該当ファイル
  - **変更**:
    ```swift
    enum AppStatus: Equatable {
        // 既存...
        case streamingTranscribing    // 追加
        case streamingCompleted       // 追加
    }
    ```
  - **仕様**: docs/spec.md 6.2
  - **完了条件**: コンパイル成功、メニューバーアイコン処理で新ステータスが認識される
  - **前提条件**: なし

- [ ] 1.6 HotKeySettings 拡張
  - **ファイル**: `WhisperPad/WhisperPad/Models/HotKeySettings.swift`
  - **変更**:
    - `var streamingHotKey: KeyComboSettings` プロパティ追加（デフォルト: `⌘⇧R`）
  - **仕様**: docs/spec.md 4.2.1
  - **完了条件**: コンパイル成功、デフォルト値が正しく設定される
  - **前提条件**: なし

---

## フェーズ 2: クライアント実装（フェーズ 1 完了後、並列実行可能）

> 2 つのワークツリーで並列開発可能

### ワークツリー 1: feature/streaming-audio-client

- [ ] 2.1 StreamingAudioService actor 作成
  - **ファイル**: `WhisperPad/WhisperPad/Clients/StreamingAudioService.swift`
  - **内容**:

    ```swift
    actor StreamingAudioService {
        private var audioProcessor: AudioProcessor?
        private var audioBuffer: [Float] = []

        func startLiveRecording() async throws -> AsyncStream<[Float]>
        func stopRecording() async
        var isRecording: Bool { get }
    }
    ```

  - **依存**: WhisperKit `AudioProcessor`
  - **完了条件**: マイク入力のリアルタイムストリームが取得可能
  - **前提条件**: フェーズ 1 完了

- [ ] 2.2 StreamingAudioClient struct 作成
  - **ファイル**: `WhisperPad/WhisperPad/Clients/StreamingAudioClient.swift`
  - **内容**:

    ```swift
    struct StreamingAudioClient: Sendable {
        var startRecording: @Sendable () async throws -> AsyncStream<[Float]>
        var stopRecording: @Sendable () async -> Void
        var isRecording: @Sendable () async -> Bool
    }

    extension StreamingAudioClient: DependencyKey {
        private static let service = StreamingAudioService()
        static var liveValue: Self { /* wrap service */ }
    }

    extension DependencyValues {
        var streamingAudio: StreamingAudioClient { /* ... */ }
    }
    ```

  - **完了条件**: `DependencyValues` に登録、`testValue` / `previewValue` 実装
  - **前提条件**: 2.1 完了

### ワークツリー 2: feature/streaming-transcription-client

- [ ] 2.3 StreamingTranscriptionService actor 作成
  - **ファイル**: `WhisperPad/WhisperPad/Clients/StreamingTranscriptionService.swift`
  - **内容**:

    ```swift
    actor StreamingTranscriptionService {
        private var whisperKit: WhisperKit?
        private var confirmedSegments: [String] = []
        private var pendingSegment: String = ""
        private var decodingPreview: String = ""

        func initialize(modelName: String?) async throws
        func processAudioChunk(_ samples: [Float]) async throws -> TranscriptionProgress
        func finalize() async throws -> String
        func reset() async
    }

    struct TranscriptionProgress: Equatable, Sendable {
        let confirmedText: String
        let pendingText: String
        let decodingText: String
        let tokensPerSecond: Double
    }
    ```

  - **依存**: WhisperKit `transcribe()`, `TranscriptionCallback`
  - **仕様**: docs/spec.md 4.6.4, 4.6.5 (確定ロジック: 2 回連続で同じ内容)
  - **完了条件**: 音声チャンクからテキストへの変換が動作
  - **前提条件**: フェーズ 1 完了

- [ ] 2.4 StreamingTranscriptionClient struct 作成
  - **ファイル**: `WhisperPad/WhisperPad/Clients/StreamingTranscriptionClient.swift`
  - **内容**:

    ```swift
    struct StreamingTranscriptionClient: Sendable {
        var initialize: @Sendable (_ modelName: String?) async throws -> Void
        var processChunk: @Sendable (_ samples: [Float]) async throws -> TranscriptionProgress
        var finalize: @Sendable () async throws -> String
        var reset: @Sendable () async -> Void
    }

    extension StreamingTranscriptionClient: DependencyKey { /* ... */ }
    extension DependencyValues { /* ... */ }
    ```

  - **完了条件**: `DependencyValues` に登録、`testValue` / `previewValue` 実装
  - **前提条件**: 2.3 完了

---

## フェーズ 3: TCA Feature 実装（フェーズ 2 完了後）

### ブランチ: feature/streaming-feature

- [ ] 3.1 StreamingTranscriptionFeature Reducer 作成
  - **ファイル**: `WhisperPad/WhisperPad/Features/StreamingTranscription/StreamingTranscriptionFeature.swift`
  - **内容**:

    ```swift
    @Reducer
    struct StreamingTranscriptionFeature {
        @ObservableState
        struct State: Equatable, Sendable {
            var status: StreamingStatus = .idle
            var confirmedText: String = ""
            var pendingText: String = ""
            var decodingText: String = ""
            var duration: TimeInterval = 0
            var tokensPerSecond: Double = 0
        }

        enum Action: Sendable {
            case startButtonTapped
            case stopButtonTapped
            case cancelButtonTapped
            case copyAndCloseButtonTapped
            case saveToFileButtonTapped

            // Internal
            case initializationCompleted
            case initializationFailed(String)
            case progressUpdated(TranscriptionProgress)
            case timerTick
            case finalizationCompleted(String)
            case finalizationFailed(String)

            // Delegate
            case delegate(Delegate)
        }

        enum Delegate: Sendable, Equatable {
            case streamingCompleted(String)
            case streamingCancelled
        }

        @Dependency(\.streamingAudio) var streamingAudio
        @Dependency(\.streamingTranscription) var streamingTranscription
        @Dependency(\.continuousClock) var clock

        var body: some Reducer<State, Action> { /* ... */ }
    }
    ```

  - **仕様**: docs/spec.md 4.6.6 状態遷移図
  - **完了条件**: 状態遷移が仕様通り動作、タイマーでの経過時間更新
  - **前提条件**: 2.2, 2.4 完了

- [ ] 3.2 StreamingTranscriptionView 作成
  - **ファイル**: `WhisperPad/WhisperPad/Features/StreamingTranscription/StreamingTranscriptionView.swift`
  - **内容**:

    ```swift
    struct StreamingTranscriptionView: View {
        @Bindable var store: StoreOf<StreamingTranscriptionFeature>

        var body: some View {
            VStack(spacing: 0) {
                HeaderView(...)      // ステータス、経過時間、閉じるボタン
                TextDisplayView(...) // 確定/未確定/デコード中テキスト
                FooterView(...)      // tok/s、ボタン群
            }
        }
    }
    ```

  - **仕様**: docs/spec.md 5.3.2-5.3.5
  - **UI 要素**:
    - ヘッダー: ステータス表示（色分け）、経過時間、✕ ボタン
    - テキスト: 自動スクロール、3 段階の透明度で表示
    - フッター: tok/s 表示、「停止」「ファイル保存」「コピーして閉じる」
  - **完了条件**: UI が仕様通りレイアウト、テキストの色分け表示
  - **前提条件**: 3.1 完了

---

## フェーズ 4: ポップアップウィンドウ（フェーズ 3 と並列可能）

### ブランチ: feature/streaming-popup

- [ ] 4.1 StreamingPopupWindow 作成
  - **ファイル**: `WhisperPad/WhisperPad/Features/StreamingTranscription/StreamingPopupWindow.swift`
  - **内容**:

    ```swift
    final class StreamingPopupWindow: NSPanel {
        private let hostingView: NSHostingView<StreamingTranscriptionView>

        init(store: StoreOf<StreamingTranscriptionFeature>) {
            // styleMask: [.borderless, .nonactivatingPanel]
            // level: .floating
            // backgroundColor: .clear
            // hasShadow: true
        }

        func showBelowMenuBarIcon(relativeTo statusItem: NSStatusItem)
        func close()
    }
    ```

  - **仕様**: docs/spec.md 5.3.1
  - **UI 仕様**:
    - サイズ: 400 × 300 px
    - 位置: メニューバーアイコン直下、中央揃え
    - 背景: `NSVisualEffectView` (material: .hudWindow)
    - 角丸: 12px
  - **完了条件**: ポップアップがメニューバー直下に正しく表示
  - **前提条件**: 3.2 完了

- [ ] 4.2 StreamingPopupWindowController 作成（オプション）
  - **ファイル**: `WhisperPad/WhisperPad/Features/StreamingTranscription/StreamingPopupWindowController.swift`
  - **役割**: ウィンドウのライフサイクル管理、フォーカス制御
  - **完了条件**: ウィンドウの表示/非表示が正しく動作
  - **前提条件**: 4.1 完了

---

## フェーズ 5: 統合（順次実行）

### ブランチ: feature/streaming-integration

- [ ] 5.1 AppReducer に StreamingTranscriptionFeature を統合
  - **ファイル**: `WhisperPad/WhisperPad/App/AppReducer.swift`
  - **変更**:

    ```swift
    struct AppReducer {
        @ObservableState
        struct State: Equatable {
            // 既存...
            var streamingTranscription: StreamingTranscriptionFeature.State = .init()
        }

        enum Action {
            // 既存...
            case streamingTranscription(StreamingTranscriptionFeature.Action)
            case startStreamingButtonTapped
            case showStreamingPopup
            case hideStreamingPopup
        }

        var body: some Reducer<State, Action> {
            // 既存...
            Scope(state: \.streamingTranscription, action: \.streamingTranscription) {
                StreamingTranscriptionFeature()
            }
        }
    }
    ```

  - **Delegate ハンドリング**:
    - `.streamingCompleted(text)` → クリップボードにコピー、appStatus を `.completed` に
    - `.streamingCancelled` → appStatus を `.idle` に
  - **完了条件**: AppReducer からストリーミング機能が制御可能
  - **前提条件**: 3.1 完了

- [ ] 5.2 AppDelegate にメニュー項目追加
  - **ファイル**: `WhisperPad/WhisperPad/App/AppDelegate.swift`
  - **変更**:
    - メニューに「🎤 リアルタイム文字起こし ⌘⇧R」を追加
    - ポップアップウィンドウの表示/非表示ロジック
    - ストリーミング中のメニューバーアイコン更新（`waveform.badge.mic`, systemPurple）
  - **仕様**: docs/spec.md 4.1.2, 6.3
  - **完了条件**: メニューからストリーミングが起動、アイコンが正しく更新
  - **前提条件**: 5.1, 4.1 完了

- [ ] 5.3 HotKeyClient にストリーミングホットキー追加
  - **ファイル**: `WhisperPad/WhisperPad/Clients/HotKeyClient.swift`
  - **変更**:
    ```swift
    var registerStreamingHotKey: @Sendable (KeyComboSettings, @escaping () -> Void) async -> Void
    var unregisterStreamingHotKey: @Sendable () async -> Void
    ```
  - **完了条件**: `⌘⇧R` でストリーミングが起動
  - **前提条件**: 1.6 完了

- [ ] 5.4 UserDefaultsClient 更新
  - **ファイル**: `WhisperPad/WhisperPad/Clients/UserDefaultsClient.swift`
  - **変更**: `WhisperPad.settings.streaming` キーの追加（既存パターンで対応可能）
  - **仕様**: docs/spec.md 7.1.1
  - **完了条件**: StreamingSettings の永続化が動作
  - **前提条件**: 1.1, 1.4 完了

- [ ] 5.5 OutputClient 拡張（オプション）
  - **ファイル**: `WhisperPad/WhisperPad/Clients/OutputClient.swift`
  - **変更**: ストリーミング結果のファイル保存メソッド追加（既存の `saveToFile` で対応可能なら不要）
  - **完了条件**: ストリーミング結果がファイルに保存可能
  - **前提条件**: なし

---

## フェーズ 6: テスト（フェーズ 5 完了後）

### ブランチ: feature/streaming-tests

- [ ] 6.1 StreamingTranscriptionFeature ユニットテスト
  - **ファイル**: `WhisperPad/WhisperPadTests/StreamingTranscriptionFeatureTests.swift`
  - **テストケース**:
    - 開始 → 初期化完了 → 録音中状態
    - 停止 → 処理中 → 完了
    - キャンセル → idle 状態
    - エラー発生 → エラー状態
    - 経過時間の更新
  - **完了条件**: 全テストケースがパス
  - **前提条件**: 3.1 完了

- [ ] 6.2 StreamingAudioClient テスト
  - **ファイル**: `WhisperPad/WhisperPadTests/StreamingAudioClientTests.swift`
  - **テストケース**:
    - 録音開始/停止
    - 権限確認
  - **完了条件**: 全テストケースがパス
  - **前提条件**: 2.2 完了

- [ ] 6.3 StreamingTranscriptionClient テスト
  - **ファイル**: `WhisperPad/WhisperPadTests/StreamingTranscriptionClientTests.swift`
  - **テストケース**:
    - 初期化
    - チャンク処理
    - 確定ロジック（2 回連続で同じ内容）
  - **完了条件**: 全テストケースがパス
  - **前提条件**: 2.4 完了

- [ ] 6.4 統合テスト
  - **テストケース**:
    - メニューからストリーミング起動 → ポップアップ表示 → 停止 → コピー
    - ホットキーからストリーミング起動 → キャンセル
    - ストリーミング → ファイル保存
  - **完了条件**: E2E シナリオが動作
  - **前提条件**: フェーズ 5 完了

---

## Git Worktree セットアップコマンド

```bash
# フェーズ 1 用（メインリポジトリで作業）
git checkout -b feature/streaming-models develop

# フェーズ 2 用（並列ワークツリー）
git gtr new feature/streaming-audio-client --from feature/streaming-models
git gtr new feature/streaming-transcription-client --from feature/streaming-models

# フェーズ 3 用
git checkout -b feature/streaming-feature develop

# フェーズ 4 用（フェーズ 3 と並列可能）
git gtr new feature/streaming-popup --from feature/streaming-feature

# フェーズ 5 用
git checkout -b feature/streaming-integration develop

# フェーズ 6 用
git checkout -b feature-streaming-tests develop

# ワークツリーでエディタを開く
git gtr editor feature-streaming-audio-client
git gtr editor feature-streaming-transcription-client
git gtr editor feature-streaming-popup

# ワークツリーの削除
git gtr rm feature-streaming-audio-client
```

---

## マージ順序

1. `feature/streaming-models` → `develop` (基盤モデル)
2. `feature/streaming-audio-client` → `develop` (並列 A)
3. `feature/streaming-transcription-client` → `develop` (並列 B)
4. `feature/streaming-feature` → `develop` (TCA Feature)
5. `feature/streaming-popup` → `develop` (ポップアップ)
6. `feature/streaming-integration` → `develop` (統合)
7. `feature/streaming-tests` → `develop` (テスト)

---

## クリティカルファイル

| ファイル                                                              | 役割                      |
| --------------------------------------------------------------------- | ------------------------- |
| `Features/StreamingTranscription/StreamingTranscriptionFeature.swift` | メイン Reducer            |
| `Features/StreamingTranscription/StreamingTranscriptionView.swift`    | ポップアップ内 View       |
| `Features/StreamingTranscription/StreamingPopupWindow.swift`          | NSPanel ラッパー          |
| `Clients/StreamingAudioClient.swift`                                  | マイク入力クライアント    |
| `Clients/StreamingTranscriptionClient.swift`                          | 文字起こしクライアント    |
| `Models/StreamingSettings.swift`                                      | 設定モデル                |
| `Models/StreamingStatus.swift`                                        | 状態 enum                 |
| `App/AppReducer.swift`                                                | 統合 Reducer              |
| `App/AppDelegate.swift`                                               | メニュー/ポップアップ管理 |
| `docs/spec.md`                                                        | 仕様書（参照用）          |

---

## 依存関係グラフ

```
フェーズ 1 (モデル)
    ├── 1.1 StreamingSettings
    ├── 1.2 StreamingStatus
    ├── 1.3 StreamingTranscriptionError
    ├── 1.4 AppSettings (← 1.1)
    ├── 1.5 AppStatus
    └── 1.6 HotKeySettings
         ↓
フェーズ 2 (クライアント) ← フェーズ 1 完了後、並列可能
    ├── 2.1 StreamingAudioService
    │    └── 2.2 StreamingAudioClient (← 2.1)
    └── 2.3 StreamingTranscriptionService
         └── 2.4 StreamingTranscriptionClient (← 2.3)
              ↓
フェーズ 3 (Feature) ← 2.2, 2.4 完了後
    ├── 3.1 StreamingTranscriptionFeature
    └── 3.2 StreamingTranscriptionView (← 3.1)
         ↓
フェーズ 4 (ポップアップ) ← 3.2 完了後 (フェーズ 3 と一部並列可能)
    ├── 4.1 StreamingPopupWindow
    └── 4.2 StreamingPopupWindowController (← 4.1)
         ↓
フェーズ 5 (統合) ← フェーズ 3, 4 完了後
    ├── 5.1 AppReducer 統合 (← 3.1)
    ├── 5.2 AppDelegate 更新 (← 5.1, 4.1)
    ├── 5.3 HotKeyClient 更新 (← 1.6)
    ├── 5.4 UserDefaultsClient 更新 (← 1.1, 1.4)
    └── 5.5 OutputClient 拡張
         ↓
フェーズ 6 (テスト) ← フェーズ 5 完了後
    ├── 6.1 Feature テスト (← 3.1)
    ├── 6.2 AudioClient テスト (← 2.2)
    ├── 6.3 TranscriptionClient テスト (← 2.4)
    └── 6.4 統合テスト (← フェーズ 5)
```

---

## 注意事項

1. **WhisperKit ストリーミング API**: `AudioProcessor.startRecordingLive()` と `TranscriptionCallback` を使用
2. **Sendable 要件**: すべての State/Action は `Sendable` 準拠が必須
3. **Actor 分離**: クライアントは Actor パターンでスレッドセーフに実装
4. **URL 生成タイミング**: async 境界を越える前に URL を生成（既存 AudioRecorderClient パターン参照）
5. **テスト**: `TestClock` を使用して時間依存のテストを決定論的に
