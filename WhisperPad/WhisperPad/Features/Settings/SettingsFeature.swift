//
//  SettingsFeature.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation

// MARK: - Settings Tab

/// 設定タブ
enum SettingsTab: String, CaseIterable, Sendable {
    case general = "一般"
    case hotkey = "ホットキー"
    case recording = "録音"
    case model = "モデル"
    case output = "出力"

    /// SF Symbol 名
    var iconName: String {
        switch self {
        case .general:
            "gear"
        case .hotkey:
            "keyboard"
        case .recording:
            "waveform"
        case .model:
            "cpu"
        case .output:
            "doc.on.clipboard"
        }
    }
}

// MARK: - Hotkey Type

/// ホットキータイプ（どのホットキーを編集中か）
enum HotkeyType: String, CaseIterable, Sendable {
    case recording
    case paste
    case openSettings
    case streaming
    case cancel
}

// MARK: - Delegate Action

/// 設定機能のデリゲートアクション
enum SettingsDelegateAction: Sendable, Equatable {
    /// 設定が変更された
    case settingsChanged(AppSettings)
    /// モデルが変更された
    case modelChanged(String)
}

// MARK: - Settings Feature

/// 設定機能の TCA Reducer
///
/// アプリケーション設定の管理、WhisperKit モデルの管理、
/// ストレージ場所の設定などを行います。
@Reducer
struct SettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 選択中のタブ
        var selectedTab: SettingsTab = .general

        /// アプリケーション設定
        var settings: AppSettings = .default

        /// 利用可能なモデル一覧
        var availableModels: [WhisperModel] = []

        /// モデル一覧を読み込み中かどうか
        var isLoadingModels: Bool = false

        /// モデルのダウンロード進捗（モデル名: 進捗 0.0-1.0）
        var downloadProgress: [String: Double] = [:]

        /// 現在ダウンロード中のモデル名
        var downloadingModelName: String?

        /// ストレージ使用量（バイト）
        var storageUsage: Int64 = 0

        /// 現在のモデル保存先 URL
        var modelStorageURL: URL?

        /// エラーメッセージ
        var errorMessage: String?

        /// 設定を保存中かどうか
        var isSaving: Bool = false

        /// ホットキー録音中のタイプ（nil = 録音なし）
        var recordingHotkeyType: HotkeyType?
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Lifecycle

        /// 画面表示時
        case onAppear
        /// 画面非表示時
        case onDisappear

        // MARK: - Tab Navigation

        /// タブを選択
        case selectTab(SettingsTab)

        // MARK: - Settings Updates

        /// 一般設定を更新
        case updateGeneralSettings(GeneralSettings)
        /// 録音設定を更新
        case updateRecordingSettings(RecordingSettings)
        /// ホットキー設定を更新
        case updateHotKeySettings(HotKeySettings)
        /// 文字起こし設定を更新
        case updateTranscriptionSettings(TranscriptionSettings)
        /// 出力設定を更新
        case updateOutputSettings(FileOutputSettings)

        // MARK: - Persistence

        /// 設定を読み込み
        case loadSettings
        /// 設定読み込み完了
        case settingsLoaded(AppSettings)
        /// 設定を保存
        case saveSettings
        /// 設定保存完了
        case settingsSaved(Result<Void, Error>)

        // MARK: - Model Management

        /// モデル一覧を取得
        case fetchModels
        /// モデル一覧取得完了
        case modelsResponse(Result<[WhisperModel], Error>)
        /// モデルを選択
        case selectModel(String)
        /// モデルをダウンロード
        case downloadModel(String)
        /// ダウンロード進捗更新
        case downloadProgress(String, Double)
        /// ダウンロード完了
        case downloadCompleted(String, Result<URL, Error>)
        /// モデルを削除
        case deleteModel(String)
        /// モデル削除完了
        case deleteModelResponse(String, Result<Void, Error>)

        // MARK: - Storage Management

        /// ストレージ使用量を計算
        case calculateStorageUsage
        /// ストレージ使用量取得完了
        case storageUsageResponse(Int64)
        /// ストレージ場所を選択
        case selectStorageLocation
        /// ストレージ場所選択完了
        case storageLocationSelected(Result<URL, Error>)
        /// ストレージ場所をデフォルトにリセット
        case resetStorageLocation

        // MARK: - Error Handling

        /// エラーをクリア
        case clearError

        // MARK: - Hotkey Recording

        /// ホットキー録音を開始
        case startRecordingHotkey(HotkeyType)
        /// ホットキー録音を停止
        case stopRecordingHotkey

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(SettingsDelegateAction)
    }

    // MARK: - Dependencies

    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.transcriptionClient) var transcriptionClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadSettings),
                    .send(.fetchModels),
                    .send(.calculateStorageUsage)
                )

            case .onDisappear:
                return .none

            case let .selectTab(tab):
                state.selectedTab = tab
                return .none

            case let .updateGeneralSettings(general):
                state.settings.general = general
                return .send(.saveSettings)

            case let .updateRecordingSettings(recording):
                state.settings.recording = recording
                return .send(.saveSettings)

            case let .updateHotKeySettings(hotKey):
                state.settings.hotKey = hotKey
                return .send(.saveSettings)

            case let .updateTranscriptionSettings(transcription):
                let previousModel = state.settings.transcription.modelName
                state.settings.transcription = transcription
                var effects: [Effect<Action>] = [.send(.saveSettings)]
                if previousModel != transcription.modelName {
                    effects.append(.send(.delegate(.modelChanged(transcription.modelName))))
                }
                return .merge(effects)

            case let .updateOutputSettings(output):
                state.settings.output = output
                return .send(.saveSettings)

            case .loadSettings:
                return .run { send in
                    let settings = await userDefaultsClient.loadSettings()
                    await send(.settingsLoaded(settings))
                }

            case let .settingsLoaded(settings):
                state.settings = settings
                if let bookmarkData = settings.transcription.storageBookmarkData {
                    return .run { send in
                        if let url = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            await transcriptionClient.setStorageLocation(url)
                        }
                        await send(.storageUsageResponse(transcriptionClient.getStorageUsage()))
                    }
                }
                return .none

            case .saveSettings:
                state.isSaving = true
                return .run { [settings = state.settings] send in
                    do {
                        try await userDefaultsClient.saveSettings(settings)
                        await send(.settingsSaved(.success(())))
                    } catch {
                        await send(.settingsSaved(.failure(error)))
                    }
                }
                .debounce(id: "saveSettings", for: .milliseconds(500), scheduler: DispatchQueue.main)

            case let .settingsSaved(result):
                state.isSaving = false
                switch result {
                case .success:
                    // ホットキー設定変更を通知（AppDelegateでホットキーを再登録）
                    NotificationCenter.default.post(
                        name: .hotKeySettingsChanged,
                        object: state.settings.hotKey
                    )
                    return .send(.delegate(.settingsChanged(state.settings)))
                case let .failure(error):
                    state.errorMessage = error.localizedDescription
                    return .none
                }

            case .fetchModels:
                state.isLoadingModels = true
                return .run { send in
                    do {
                        let modelNames = try await transcriptionClient.fetchAvailableModels()
                        let recommendedModel = await transcriptionClient.recommendedModel()
                        var models: [WhisperModel] = []
                        for name in modelNames {
                            let isDownloaded = await transcriptionClient.isModelDownloaded(name)
                            models.append(WhisperModel.from(
                                id: name,
                                isDownloaded: isDownloaded,
                                isRecommended: name == recommendedModel
                            ))
                        }
                        models.sort { lhs, rhs in
                            let lhsKnown = WhisperModel.knownModels[lhs.id] != nil
                            let rhsKnown = WhisperModel.knownModels[rhs.id] != nil
                            if lhsKnown, !rhsKnown { return true }
                            if !lhsKnown, rhsKnown { return false }
                            return lhs.id < rhs.id
                        }
                        await send(.modelsResponse(.success(models)))
                    } catch {
                        await send(.modelsResponse(.failure(error)))
                    }
                }

            case let .modelsResponse(result):
                state.isLoadingModels = false
                switch result {
                case let .success(models):
                    state.availableModels = models
                case let .failure(error):
                    state.errorMessage = error.localizedDescription
                }
                return .none

            case let .selectModel(modelName):
                state.settings.transcription.modelName = modelName
                return .merge(
                    .send(.saveSettings),
                    .send(.delegate(.modelChanged(modelName)))
                )

            case let .downloadModel(modelName):
                state.downloadingModelName = modelName
                state.downloadProgress[modelName] = 0
                return .run { send in
                    do {
                        let downloadedURL = try await transcriptionClient.downloadModel(modelName) { progress in
                            Task { await send(.downloadProgress(modelName, progress)) }
                        }
                        await send(.downloadCompleted(modelName, .success(downloadedURL)))
                    } catch {
                        await send(.downloadCompleted(modelName, .failure(error)))
                    }
                }
                .cancellable(id: "download-\(modelName)")

            case let .downloadProgress(modelName, progress):
                state.downloadProgress[modelName] = progress
                return .none

            case let .downloadCompleted(modelName, result):
                state.downloadingModelName = nil
                state.downloadProgress.removeValue(forKey: modelName)
                switch result {
                case .success:
                    if let index = state.availableModels.firstIndex(where: { $0.id == modelName }) {
                        state.availableModels[index].isDownloaded = true
                    }
                    return .send(.calculateStorageUsage)
                case let .failure(error):
                    state.errorMessage = "ダウンロードに失敗しました: \(error.localizedDescription)"
                    return .none
                }

            case let .deleteModel(modelName):
                return .run { send in
                    do {
                        try await transcriptionClient.deleteModel(modelName)
                        await send(.deleteModelResponse(modelName, .success(())))
                    } catch {
                        await send(.deleteModelResponse(modelName, .failure(error)))
                    }
                }

            case let .deleteModelResponse(modelName, result):
                switch result {
                case .success:
                    if let index = state.availableModels.firstIndex(where: { $0.id == modelName }) {
                        state.availableModels[index].isDownloaded = false
                    }
                    return .send(.calculateStorageUsage)
                case let .failure(error):
                    state.errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                    return .none
                }

            case .calculateStorageUsage:
                return .run { send in
                    let usage = await transcriptionClient.getStorageUsage()
                    await send(.storageUsageResponse(usage))
                }

            case let .storageUsageResponse(usage):
                state.storageUsage = usage
                return .none

            case .selectStorageLocation:
                return .run { send in
                    await MainActor.run {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.message = "モデルの保存先フォルダを選択してください"
                        panel.prompt = "選択"
                        if panel.runModal() == .OK, let url = panel.url {
                            Task { await send(.storageLocationSelected(.success(url))) }
                        }
                    }
                }

            case let .storageLocationSelected(result):
                switch result {
                case let .success(url):
                    return .run { [settings = state.settings] send in
                        do {
                            let bookmarkData = try await userDefaultsClient.createBookmark(url)
                            var newSettings = settings
                            newSettings.transcription.customStorageURL = url
                            newSettings.transcription.storageBookmarkData = bookmarkData
                            await userDefaultsClient.saveStorageBookmark(bookmarkData)
                            await transcriptionClient.setStorageLocation(url)
                            try await userDefaultsClient.saveSettings(newSettings)
                            await send(.settingsLoaded(newSettings))
                            await send(.calculateStorageUsage)
                        } catch {
                            await send(.storageLocationSelected(.failure(error)))
                        }
                    }
                case let .failure(error):
                    state.errorMessage = "ストレージ場所の設定に失敗しました: \(error.localizedDescription)"
                    return .none
                }

            case .resetStorageLocation:
                state.settings.transcription.customStorageURL = nil
                state.settings.transcription.storageBookmarkData = nil
                return .run { send in
                    await transcriptionClient.setStorageLocation(nil)
                    await send(.saveSettings)
                    await send(.calculateStorageUsage)
                }

            case .clearError:
                state.errorMessage = nil
                return .none

            case let .startRecordingHotkey(type):
                state.recordingHotkeyType = type
                return .none

            case .stopRecordingHotkey:
                state.recordingHotkeyType = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
