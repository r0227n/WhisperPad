---
name: dependency-research
description: 'WhisperPad 依存ライブラリの調査知見。HotKey, WhisperKit, TCA の挙動、エラーハンドリング、ベストプラクティス。Keywords: HotKey, WhisperKit, TCA, Carbon, CoreML, dependency.'
---

# WhisperPad 依存ライブラリ調査知見

WhisperPad で使用している主要ライブラリの調査で得られた知見。

## HotKey (soffes/HotKey)

### 概要

- リポジトリ: https://github.com/soffes/HotKey
- 用途: グローバルホットキー登録
- 内部 API: Carbon `RegisterEventHotKey`

### 重要な発見: サイレント失敗

**DeepWiki 調査結果**:

> If `RegisterEventHotKey` fails, the `HotKeysController` handles the error
> silently by returning early from the register function. The package does
> not throw an error or provide explicit error handling.

**影響**:

- 設定は保存されるが、実際のホットキーは登録されない
- ユーザーは問題に気づかない

**対応**:

- Carbon API のテスト登録に依存しない
- ブロックリストアプローチを採用

### Carbon API の挙動

**RegisterEventHotKey 戻り値**:

- `noErr (0)`: 成功
- `-9878`: ホットキー既に使用中（他アプリ）
- その他: 様々なエラー

**問題点**:

- 環境依存（他アプリの登録状況で結果が変わる）
- 偽陽性が多い
- テスト登録と実登録のタイミング差

### ブロックリストアプローチ

**理由**:

1. 主要なシステムショートカット（51個）をブロックリストでカバー
2. Carbon API は信頼性が低い
3. 他アプリとの競合はユーザー判断

**実装**:

```swift
static func canRegister(
    carbonKeyCode: UInt32,
    carbonModifiers: UInt32
) -> Result<Void, ValidationError> {
    if isSystemReservedShortcut(...) {
        return .failure(.reservedSystemShortcut)
    }
    return .success(())
}
```

### HotKey 登録パターン

```swift
let hotKey = HotKey(
    carbonKeyCode: combo.carbonKeyCode,
    carbonModifiers: combo.carbonModifiers
)
hotKey.keyDownHandler = { /* handler */ }
```

**注意**: `HotKey` インスタンスを保持し続ける必要あり。

---

## WhisperKit (argmaxinc/WhisperKit)

### 概要

- リポジトリ: https://github.com/argmaxinc/WhisperKit
- 用途: オンデバイス音声認識
- 内部 API: CoreML

### 初期化パターン

```swift
let whisperKit = try await WhisperKit(
    model: "base",
    downloadBase: nil,
    modelRepo: "argmaxinc/whisperkit-coreml",
    modelFolder: nil,
    tokenizerFolder: nil,
    computeOptions: nil,
    audioProcessor: nil,
    featureExtractor: nil,
    textDecoder: nil,
    logLevel: .error
)
```

### モデルオプション

| モデル   | サイズ | 精度 | 速度 |
| -------- | ------ | ---- | ---- |
| tiny     | ~39MB  | 低   | 最速 |
| base     | ~74MB  | 中低 | 速い |
| small    | ~244MB | 中   | 普通 |
| medium   | ~769MB | 中高 | 遅い |
| large-v3 | ~1.5GB | 高   | 最遅 |

### 初期化中の UX

**問題**: 初期化に数秒かかる

**対応**:

- ダイアログ表示で初期化中であることを通知
- 非同期で初期化

```swift
// AppReducer での実装例
case .initialize:
    state.showInitializingDialog = true
    return .run { send in
        let kit = try await WhisperKit(...)
        await send(.initializeCompleted(kit))
    }

case .initializeCompleted:
    state.showInitializingDialog = false
```

### 音声認識パターン

```swift
let result = try await whisperKit.transcribe(
    audioPath: audioURL.path,
    decodeOptions: DecodingOptions(
        language: "ja",
        task: .transcribe
    )
)
```

---

## TCA (pointfreeco/swift-composable-architecture)

### 概要

- リポジトリ: https://github.com/pointfreeco/swift-composable-architecture
- バージョン: 1.23.1+
- 用途: 状態管理

### Dependency 注入パターン

**定義**:

```swift
// Client プロトコル
struct HotKeyClient {
    var registerRecording: @Sendable (KeyComboSettings, @escaping () -> Void) -> Void
}

// DependencyKey
extension HotKeyClient: DependencyKey {
    static var liveValue: HotKeyClient = .live
    static var testValue: HotKeyClient = .test
}

// DependencyValues 拡張
extension DependencyValues {
    var hotKeyClient: HotKeyClient {
        get { self[HotKeyClient.self] }
        set { self[HotKeyClient.self] = newValue }
    }
}
```

**使用**:

```swift
@Reducer
struct SettingsFeature {
    @Dependency(\.hotKeyClient) var hotKeyClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        // hotKeyClient を使用
    }
}
```

### TestStore 使用方法

```swift
@Test
func test_example() async {
    let store = TestStore(
        initialState: SettingsFeature.State()
    ) {
        SettingsFeature()
    } withDependencies: {
        $0.hotKeyClient = .test
    }

    await store.send(.action) {
        $0.someState = expectedValue
    }
}
```

### Effect パターン

**非同期処理**:

```swift
return .run { send in
    let result = try await someAsyncWork()
    await send(.completed(result))
}
```

**同期処理**:

```swift
return .send(.someAction)
```

**複数 Effect**:

```swift
return .merge(
    .send(.action1),
    .run { send in await send(.action2) }
)
```

---

## 調査方法

### DeepWiki MCP を使用

```typescript
// 構造確認
mcp__deepwiki__read_wiki_structure({
  repoName: 'soffes/HotKey',
})

// 質問
mcp__deepwiki__ask_question({
  repoName: 'soffes/HotKey',
  question: 'What happens when RegisterEventHotKey fails?',
})
```

### ソースコード直接確認

```bash
gh repo clone soffes/HotKey /tmp/HotKey
grep -r "RegisterEventHotKey" /tmp/HotKey
```

---

## 関連スキル

- `deepwiki-research:deepwiki-research`: DeepWiki MCP 調査
- `tdd-worktree:tdd-dev`: TDD 開発ワークフロー
- `feature-dev-knowledge`: 機能開発ナレッジ
