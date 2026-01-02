# WhisperPad UI リファクタリング項目

## 調査結果サマリー

コードベースを調査した結果、以下のリファクタリング候補を発見しました。

---

## 優先度 1（高）- 効果が大きい

### 1. Binding パターンの共通化

**問題**: Settings 配下で 22 箇所、同じ `Binding(get:set:)` パターンが繰り返されている

```swift
// 現状: 各TabViewで繰り返し
SettingRowWithIcon(
    isOn: Binding(
        get: { store.settings.general.launchAtLogin },
        set: { newValue in
            var general = store.settings.general
            general.launchAtLogin = newValue
            store.send(.updateGeneralSettings(general))
        }
    )
)
```

**対象ファイル**:

- `Features/Settings/Tabs/GeneralSettingsTab.swift`
- `Features/Settings/Tabs/RecordingSettingsTab.swift`
- `Features/Settings/Tabs/ModelSettingsTab.swift`
- `Features/Settings/Tabs/HotkeySettingsTab.swift`

**削減見込み**: 約 200 行

---

### 2. StreamingTranscriptionView の分割

**問題**: 415 行のファイルに複数の完全な View が内包されている

**現状の構造**:

- HeaderView（private）
- TextDisplayView（private）
- FooterView（private）
- StatusIndicator（private）
- PulseModifier（private ViewModifier）

**対象ファイル**:

- `Features/StreamingTranscription/StreamingTranscriptionView.swift`

---

### 3. Popover コンポーネントの統一

**問題**: 同じ構造の 2 つの Popover が別々に実装されている

**対象ファイル**:

- `Features/Settings/Components/NotificationDetailsPopover.swift`
- `Features/Settings/Components/FileOutputDetailsPopover.swift`

**共通化可能な要素**:

- ヘッダー部分
- パディング・マージン
- デフォルトリセットボタン

---

## 優先度 2（中）- 保守性向上

### 4. デザイントークンの定義

**問題**: ハードコードされた数値が混在している

| カテゴリ       | 現状の値                   |
| -------------- | -------------------------- |
| パディング     | 4, 6, 8, 10, 12, 16, 20 px |
| 角丸           | 4, 6, 8, 12 px             |
| フォントサイズ | 12, 14, 18 pt              |
| 色透明度       | 0.1, 0.2, 0.3              |

---

### 5. private View コンポーネントの抽出

**問題**: 再利用可能なコンポーネントがファイル内で private 定義されている

**対象**:

- `ShortcutListRow` (HotkeySettingsTab.swift 内)
- `ShortcutDetailPanel` (HotkeySettingsTab.swift 内)
- `StatusIndicator` (StreamingTranscriptionView.swift 内)
- `PulseModifier` (StreamingTranscriptionView.swift 内)

---

### 6. SettingsFeature の SubReducer 化

**問題**: 612 行で `file_length` SwiftLint disable が必要

**現状**:

- State: 14 個のプロパティ
- Action: 20+ ケース
- 単一の大きな Reducer

---

## 優先度 3（低）- 細かな改善

### 7. SettingRowWithIcon の拡張

- Picker, Stepper 用の convenience initializer 追加
- 現在は Toggle 用のみ

### 8. アクセシビリティの一貫性

- 一部コンポーネントで `.accessibilityLabel` が不足

### 9. ByteCountFormatter の共通化

- ModelSettingsTab でのみ使用
- 他でも活用可能

---

## 現状の良い点

- TCA アーキテクチャへの準拠は良好
- `SettingRowWithIcon` などの再利用可能なコンポーネントが存在
- アクセシビリティ対応が進んでいる
- コメントが充実している

---

## コード品質メトリクス

| 項目               | 評価 | コメント                              |
| ------------------ | ---- | ------------------------------------- |
| TCA 準拠度         | 8/10 | ほぼ準拠だが、State 構造が複雑        |
| 再利用性           | 6/10 | Binding パターン重複が多い            |
| アクセシビリティ   | 7/10 | 実装されているが、不均一              |
| 命名規則一貫性     | 8/10 | 全体的に良好だが、細部に揺らぎ        |
| コンポーネント分離 | 7/10 | 一部は private 構造体でカプセル化     |
| テスト可能性       | 7/10 | Feature は独立テスト可能。View は困難 |
