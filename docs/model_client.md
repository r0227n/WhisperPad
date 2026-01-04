# ModelClient 仕様書

## 概要

ModelClient は WhisperKit モデルの管理を一元化する TCA Dependency です。
メニューバーと設定画面の両方から利用され、データソースとエラーハンドリングを統一します。

## API 一覧

### モデル一覧取得

| API                     | 型                            | 説明                               |
| ----------------------- | ----------------------------- | ---------------------------------- |
| `fetchAvailableModels`  | `() async throws -> [String]` | 利用可能な全モデル一覧を取得       |
| `fetchDownloadedModels` | `() async throws -> [String]` | ダウンロード済みモデル一覧を取得   |
| `recommendedModel`      | `() async -> String`          | デバイス推奨モデルを取得           |
| `isModelDownloaded`     | `(String) async -> Bool`      | 指定モデルがダウンロード済みか確認 |

### モデルダウンロード・削除

| API             | 型                                                  | 説明                                         |
| --------------- | --------------------------------------------------- | -------------------------------------------- |
| `downloadModel` | `(String, ((Double) -> Void)?) async throws -> URL` | モデルをダウンロード（進捗コールバック付き） |
| `deleteModel`   | `(String) async throws -> Void`                     | モデルを削除                                 |

### デフォルトモデル管理

| API                    | 型                                               | 説明                                                                |
| ---------------------- | ------------------------------------------------ | ------------------------------------------------------------------- |
| `loadDefaultModel`     | `() async -> String?`                            | UserDefaults からデフォルトモデルを非同期読み込み                   |
| `loadDefaultModelSync` | `() -> String?`                                  | UserDefaults からデフォルトモデルを同期読み込み（メニュー初期化用） |
| `saveDefaultModel`     | `(String?) async -> Void`                        | デフォルトモデルを保存（nil で削除）                                |
| `validateDefaultModel` | `([String]) -> Result<String, ModelClientError>` | デフォルトモデルの有効性を検証                                      |

### ストレージ管理

| API                  | 型                     | 説明                                             |
| -------------------- | ---------------------- | ------------------------------------------------ |
| `getStorageUsage`    | `() async -> Int64`    | ストレージ使用量（バイト）を取得                 |
| `getModelStorageURL` | `() async -> URL`      | モデル保存先 URL を取得                          |
| `setStorageLocation` | `(URL?) async -> Void` | カスタムストレージ場所を設定（nil でデフォルト） |

## エラー型

```swift
enum ModelClientError: Error, Equatable, LocalizedError {
    case fetchAvailableModelsFailed(String)  // 利用可能モデル取得失敗
    case fetchDownloadedModelsFailed(String) // ダウンロード済みモデル取得失敗
    case noModelsFound                        // モデルが0件
    case invalidDefaultModel(String)          // デフォルトモデルが無効
    case selectionFailed(String)              // モデル選択失敗
    case downloadFailed(String)               // ダウンロード失敗
    case deletionFailed(String)               // 削除失敗
}
```

## エラーハンドリング

### NSAlert ダイアログ表示条件

| エラーケース         | タイトルキー               | 説明                                               |
| -------------------- | -------------------------- | -------------------------------------------------- |
| モデル取得失敗       | `error.dialog.model.title` | API 呼び出しが throw した場合                      |
| モデルが見つからない | `error.dialog.model.title` | downloadedModels が空の場合                        |
| デフォルトモデル無効 | `error.dialog.model.title` | 保存されたモデルがダウンロード済み一覧に存在しない |
| モデル選択失敗       | `error.dialog.model.title` | saveDefaultModel が失敗した場合                    |

### ダイアログ表示方法

既存の`showLocalizedAlert`関数を使用：

```swift
showLocalizedAlert(
    style: .critical,
    titleKey: "error.dialog.model.title",
    message: error.localizedDescription,
    languageCode: languageCode,
    iconSettings: iconSettings
)
```

## データフロー

### メニューバー（AppDelegate）

```
menuWillOpen → refreshModelSubmenu()
    ↓
modelClient.fetchDownloadedModels()
    ↓
modelClient.validateDefaultModel(models)
    ↓
成功: updateModelSubmenuItems()
失敗: showModelErrorAlert()
```

### 設定画面（SettingsFeature）

```
.onAppear → .fetchModels / .fetchDownloadedModels
    ↓
modelClient.fetchAvailableModels() / fetchDownloadedModels()
    ↓
.modelsResponse / .downloadedModelsResponse
    ↓
state.availableModels / state.downloadedModels 更新
エラー時: state.errorMessage 設定 → .alert表示
```

## 移行元 API

### TranscriptionClient（削除対象）

- `fetchAvailableModels`
- `recommendedModel`
- `isModelDownloaded`
- `fetchDownloadedModels`
- `downloadModel`
- `getStorageUsage`
- `getModelStorageURL`
- `setStorageLocation`
- `deleteModel`

### UserDefaultsClient（削除対象）

- `loadDefaultModel`
- `saveDefaultModel`

## 使用箇所

| ファイル                 | 用途                               |
| ------------------------ | ---------------------------------- |
| `AppDelegate.swift`      | メニューモデル選択、キャッシュ管理 |
| `AppDelegate+Menu.swift` | サブメニュー構築、モデル表示       |
| `SettingsFeature.swift`  | モデル一覧表示、ダウンロード/削除  |
| `AppReducer.swift`       | モデル選択アクションのルーティング |
