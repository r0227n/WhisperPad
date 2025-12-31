# WhisperPad 設定画面 並列開発タスク

> **UI/UX 設計**: 5 タブ構成（一般 | ホットキー | 録音 | モデル | 出力）
> **フレームサイズ**: 520x500 (現状: 500x450)
> **履歴**: 別ウィンドウで表示（macOS HIG 準拠）
> **録音制限**: 技術的制約なし → 上限撤廃（ユーザー任意設定）

---

## フェーズ 1: 基盤（順次実行 - 最初に完了必須）

### ブランチ: feature/settings-models

- [ ] 1.1 HotKeySettings モデル作成
  - ファイル: `WhisperPad/WhisperPad/Models/HotKeySettings.swift`
  - 内容:
    - `KeyComboSettings` 構造体 (carbonKeyCode, carbonModifiers)
    - `RecordingMode` enum (toggle, pushToTalk)
    - `recordingHotKey`, `pasteHotKey`, `openSettingsHotKey` プロパティ
  - 仕様: docs/spec.md 4.2.3 ホットキー登録仕様

- [ ] 1.2 RecordingSettings モデル作成
  - ファイル: `WhisperPad/WhisperPad/Models/RecordingSettings.swift`
  - 内容:
    - `inputDeviceID: String?` (nil = システムデフォルト)
    - `maxDuration: TimeInterval?` (**nil = 無制限**, デフォルト: nil)
    - `silenceDetectionEnabled: Bool`
    - `silenceThreshold: Float` (-40dB)
    - `silenceDuration: TimeInterval` (**上限なし**, デフォルト: 3 秒)
  - 仕様: docs/spec.md 4.3.2 録音制限

- [ ] 1.3 AppSettings 更新
  - ファイル: `WhisperPad/WhisperPad/Models/AppSettings.swift`
  - 変更:
    - `var hotKey: HotKeySettings` プロパティ追加
    - `var recording: RecordingSettings` プロパティ追加
    - `static let default` 更新

- [ ] 1.4 UserDefaultsClient 更新
  - ファイル: `WhisperPad/WhisperPad/Clients/UserDefaultsClient.swift`
  - 変更: 新しい設定キーの追加（既存の JSON 永続化で対応可能）

---

## フェーズ 2: 並列開発（フェーズ 1 完了後、同時実行可能）

> 3 つのワークツリーで並列開発可能

### ワークツリー 1: feature/hotkey-client

- [x] 2.1 HotKeyClient 基本実装（完了）
  - ファイル: `WhisperPad/WhisperPad/Clients/HotKeyClient.swift`
  - 実装済み:
    - `registerOpenSettings(handler:)` - 設定を開くホットキー登録
    - `unregisterOpenSettings()` - 解除
    - `checkAccessibilityPermission()` - 権限確認
    - `requestAccessibilityPermission()` - 権限リクエスト
  - 依存: HotKey ライブラリ (soffes/HotKey)

- [ ] 2.1.1 HotKeyClient 拡張
  - ファイル: `WhisperPad/WhisperPad/Clients/HotKeyClient.swift`
  - 追加インターフェース:

    ```swift
    struct HotKeyClient: Sendable {
        // 既存
        var registerOpenSettings: @Sendable (@escaping () -> Void) async throws -> Void
        var unregisterOpenSettings: @Sendable () async -> Void
        var checkAccessibilityPermission: @Sendable () -> Bool
        var requestAccessibilityPermission: @Sendable () -> Void

        // 追加が必要
        var registerRecordingHotKey: @Sendable (KeyComboSettings, @escaping () -> Void, @escaping () -> Void) async -> Void
        var registerPasteHotKey: @Sendable (KeyComboSettings, @escaping () -> Void) async -> Void
        var updateOpenSettingsHotKey: @Sendable (KeyComboSettings) async -> Void
        var unregisterAll: @Sendable () async -> Void
    }
    ```

  - Push-to-Talk 対応: keyDownHandler, keyUpHandler

### ワークツリー 2: feature/settings-hotkey-tab

- [ ] 2.2 HotkeyRecorderView コンポーネント
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/Components/HotkeyRecorderView.swift`
  - UI 仕様:
    - クリックで入力モード開始
    - 現在のキーコンボ表示 (例: "⌥ Space")
    - クリアボタン
    - 競合検出・警告表示
  - アクセシビリティ: VoiceOver 対応

- [ ] 2.3 HotkeySettingsTab 実装
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/Tabs/HotkeySettingsTab.swift`
  - UI 構成:

    ```
    【ホットキー設定】

    セクション: 録音
    ├─ 録音開始/停止: [⌥ Space] [変更]
    └─ 録音モード:
       ○ トグル（1回押しで開始/停止）
       ○ プッシュ・トゥ・トーク（押している間のみ録音）

    セクション: 出力
    └─ 最後の書き起こしをペースト: [⌘⇧V] [変更]

    セクション: アプリ
    └─ 設定を開く: [⌘⇧,] [変更]

    セクション: 注意
    └─ ⚠️ 他のアプリと競合する場合は変更してください
    ```

### ワークツリー 3: feature/settings-recording-tab

- [ ] 2.4 RecordingSettingsTab 実装
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/Tabs/RecordingSettingsTab.swift`
  - UI 構成:

    ```
    【録音設定】

    セクション: 入力デバイス
    ├─ デバイス: [MacBook Pro マイク ▼]
    └─ レベルメーター: ████████░░░░░░░░ -12dB (オプション)

    セクション: 録音時間
    ├─ ☑ 無制限
    └─ (無効時) 最大録音時間: [____] 秒 (TextField)

    セクション: 無音検出
    ├─ □ 無音検出で自動停止
    └─ (有効時) 無音判定時間: [____] 秒 (TextField、上限なし)
    ```

  - 依存: AVAudioSession (入力デバイス列挙)

---

## フェーズ 3: 統合（順次実行）

### ブランチ: feature/settings-integration

- [ ] 3.1 SettingsTab enum 更新
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/SettingsFeature.swift`
  - 変更:

    ```swift
    enum SettingsTab: String, CaseIterable, Sendable {
        case general = "一般"
        case hotkey = "ホットキー"  // NEW
        case recording = "録音"      // NEW
        case model = "モデル"
        case output = "出力"

        var iconName: String {
            switch self {
            case .general: "gear"
            case .hotkey: "keyboard"
            case .recording: "waveform"
            case .model: "cpu"
            case .output: "doc.on.clipboard"
            }
        }
    }
    ```

- [ ] 3.2 SettingsFeature State/Action 拡張
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/SettingsFeature.swift`
  - State 追加:
    - `var isRecordingHotkey: Bool = false`
    - `var hotkeyConflict: String?`
    - `var availableInputDevices: [AudioInputDevice] = []`
  - Action 追加:
    - `case updateHotKeySettings(HotKeySettings)`
    - `case updateRecordingSettings(RecordingSettings)`
    - `case startRecordingHotkey(HotkeyType)`
    - `case hotkeyRecorded(HotkeyType, KeyComboSettings)`
    - `case fetchInputDevices`
    - `case inputDevicesResponse([AudioInputDevice])`
  - HotkeyType enum:

    ```swift
    enum HotkeyType: String, CaseIterable, Sendable {
        case recording
        case paste
        case openSettings
    }
    ```

- [ ] 3.3 SettingsView TabView 更新
  - ファイル: `WhisperPad/WhisperPad/Features/Settings/SettingsView.swift`
  - 変更:
    - TabView に 2 つの新タブ追加
    - フレームサイズを 520x500 に変更
    - タブにアイコン追加 (Label with systemImage)

- [ ] 3.4 統合テスト
  - タブ切り替え動作確認
  - 設定変更の永続化確認
  - ホットキー登録・解除の動作確認
  - 入力デバイス切り替えの動作確認

---

## Git Worktree セットアップコマンド

> [git-worktree-runner (gtr)](https://github.com/coderabbitai/git-worktree-runner) を使用

```bash
# フェーズ1用 (メインリポジトリで作業)
git checkout -b feature/settings-models develop

# フェーズ2用（並列ワークツリー）
git gtr new feature/hotkey-client --from develop
git gtr new feature/settings-hotkey-tab --from develop
git gtr new feature/settings-recording-tab --from develop

# フェーズ3用
git checkout -b feature/settings-integration develop

# ワークツリーでエディタを開く
git gtr editor feature-hotkey-client
git gtr editor feature-settings-hotkey-tab
git gtr editor feature-settings-recording-tab

# ワークツリーの削除
git gtr rm feature-hotkey-client
```

---

## マージ順序

1. `feature/settings-models` → `develop` (基盤)
2. `feature/hotkey-client` → `develop` (並列 A)
3. `feature/settings-hotkey-tab` → `develop` (並列 B)
4. `feature/settings-recording-tab` → `develop` (並列 C)
5. `feature/settings-integration` → `develop` (統合)

---

## 追加タスク: 仕様書更新

- [ ] docs/spec.md 4.3.2 録音制限の更新
  ```diff
  - | 最大録音時間     | 60 秒        | 10 秒〜300 秒 |
  + | 最大録音時間     | 無制限       | 任意の秒数（0 = 無制限） |
  - | 無音自動停止時間 | 3 秒         | 1 秒〜10 秒   |
  + | 無音自動停止時間 | 3 秒         | 任意の秒数     |
  ```

---

## クリティカルファイル

| ファイル                                  | 役割             |
| ----------------------------------------- | ---------------- |
| `Features/Settings/SettingsFeature.swift` | メイン Reducer   |
| `Features/Settings/SettingsView.swift`    | ルートビュー     |
| `Features/Settings/Tabs/*.swift`          | 各タブビュー     |
| `Models/AppSettings.swift`                | 設定モデル集約   |
| `Clients/UserDefaultsClient.swift`        | 永続化           |
| `docs/spec.md`                            | 仕様書（参照用） |
