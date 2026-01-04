// swiftlint:disable file_length
//
//  SettingsFeature.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation
import OSLog

// MARK: - Settings Feature

/// 設定機能の TCA Reducer
///
/// アプリケーション設定の管理、WhisperKit モデルの管理、
/// ストレージ場所の設定などを行います。
@Reducer
// swiftlint:disable:next type_body_length
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

        /// ダウンロード済みモデル一覧（ローカルディレクトリスキャンで取得）
        var downloadedModels: [WhisperModel] = []

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

        /// 利用可能な入力デバイス一覧
        var availableInputDevices: [AudioInputDevice] = []

        /// ホットキー競合警告メッセージ
        var hotkeyConflict: String?

        /// システム競合アラートの表示フラグ
        var showHotkeyConflictAlert = false

        /// 競合しているhotkeyタイプ（アラート表示用）
        var conflictingHotkeyType: HotkeyType?

        /// 競合前の設定値（ロールバック用）
        var previousHotKeySettings: HotKeySettings?

        /// 重複検出アラートの表示フラグ
        var showDuplicateHotkeyAlert = false

        /// 重複している相手のホットキータイプ
        var duplicateWithHotkeyType: HotkeyType?

        /// システム予約済みショートカットアラートの表示フラグ
        var showSystemReservedAlert = false

        /// 削除確認対象のモデル名
        var modelToDelete: String?

        /// 選択中のショートカット（ホットキー設定タブ用）
        var selectedShortcut: HotkeyType?

        /// 利用可能な文字起こし言語一覧
        var availableLanguages: [TranscriptionLanguage] = []

        /// 現在の音声レベル（dB）
        var currentAudioLevel: Float = -60.0

        /// 音声レベル監視中かどうか
        var isMonitoringAudio: Bool = false
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
        /// 出力ディレクトリのブックマークが作成された
        case outputBookmarkCreated(Data)
        /// 出力ディレクトリのブックマークが解決された
        case outputDirectoryResolved(URL)

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
        /// ダウンロード済みモデル一覧を取得（ローカルスキャン）
        case fetchDownloadedModels
        /// ダウンロード済みモデル一覧取得完了
        case downloadedModelsResponse([WhisperModel])
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
        /// モデル削除ボタンがタップされた（確認ダイアログを表示）
        case deleteModelButtonTapped(String)
        /// モデル削除を確認
        case confirmDeleteModel
        /// モデル削除をキャンセル
        case cancelDeleteModel
        /// モデル削除完了
        case deleteModelResponse(String, Result<Void, Error>)

        // MARK: - Storage Management

        /// ストレージ使用量を計算
        case calculateStorageUsage
        /// ストレージ使用量取得完了
        case storageUsageResponse(Int64)
        /// モデル保存先URLを取得
        case fetchModelStorageURL
        /// モデル保存先URL取得完了
        case modelStorageURLResponse(URL)
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
        /// ショートカットを選択
        case selectShortcut(HotkeyType?)

        // MARK: - Input Devices

        /// 入力デバイス一覧を取得
        case fetchInputDevices
        /// 入力デバイス一覧取得完了
        case inputDevicesResponse([AudioInputDevice])

        // MARK: - Audio Level Monitoring

        /// 音声レベル監視をトグル
        case toggleAudioMonitoring
        /// 音声レベル監視を開始
        case startAudioLevelObservation
        /// 音声レベル監視を停止
        case stopAudioLevelObservation
        /// 音声レベルが更新された
        case audioLevelUpdated(Float)

        // MARK: - Hotkey Conflict

        /// ホットキー競合をチェック
        case checkHotkeyConflict
        /// hotkey更新前に検証を実行
        case validateAndUpdateHotkey(HotkeyType, HotKeySettings.KeyComboSettings)
        /// システム競合が検出された
        case hotkeyConflictDetected(HotkeyType)
        /// 競合アラートを閉じた
        case dismissConflictAlert
        /// アプリ内重複が検出された
        case duplicateHotkeyDetected(HotkeyType, duplicateWith: HotkeyType)
        /// 重複アラートを閉じた
        case dismissDuplicateAlert
        /// システム予約済みショートカットが検出された
        case systemReservedShortcutDetected(HotkeyType)
        /// システム予約済みアラートを閉じた
        case dismissSystemReservedAlert

        // MARK: - Menu Bar Icon

        /// メニューバーアイコン設定をデフォルトにリセット
        case resetMenuBarIconSettings
        /// 特定の状態のアイコン設定をデフォルトにリセット
        case resetIconSetting(IconConfigStatus)

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(SettingsDelegateAction)
    }

    // MARK: - Dependencies

    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.modelClient) var modelClient
    @Dependency(\.audioRecorder) var audioRecorder
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 利用可能な言語を読み込み
                let allLanguages = TranscriptionLanguage.allSupported

                // 現在選択されているモデルが English-only の場合は言語を制限
                if state.settings.transcription.modelName.hasSuffix(".en") {
                    state.availableLanguages = allLanguages.filter {
                        $0.code == "auto" || $0.code == "en"
                    }
                } else {
                    state.availableLanguages = allLanguages
                }

                return .merge(
                    .send(.loadSettings),
                    .send(.fetchModels),
                    .send(.calculateStorageUsage),
                    .send(.fetchInputDevices),
                    .send(.checkHotkeyConflict),
                    .send(.fetchModelStorageURL)
                )

            case .onDisappear:
                // 音声レベル監視が有効な場合は停止
                if state.isMonitoringAudio {
                    return .send(.stopAudioLevelObservation)
                }
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
                return .merge(
                    .send(.saveSettings),
                    .send(.checkHotkeyConflict)
                )

            case let .updateTranscriptionSettings(transcription):
                let previousModel = state.settings.transcription.modelName
                state.settings.transcription = transcription
                var effects: [Effect<Action>] = [.send(.saveSettings)]
                if previousModel != transcription.modelName {
                    effects.append(.send(.delegate(.modelChanged(transcription.modelName))))
                }
                return .merge(effects)

            case let .updateOutputSettings(output):
                let previousDirectory = state.settings.output.outputDirectory
                state.settings.output = output

                // 出力ディレクトリが変更された場合、ブックマークを作成
                if output.outputDirectory != previousDirectory {
                    return .run { [userDefaultsClient] send in
                        do {
                            let bookmarkData = try await userDefaultsClient.createBookmark(
                                output.outputDirectory
                            )
                            await send(.outputBookmarkCreated(bookmarkData))
                        } catch {
                            // ブックマーク作成失敗（ログのみ、デフォルトパスでは不要）
                        }
                        await send(.saveSettings)
                    }
                }

                return .send(.saveSettings)

            case .loadSettings:
                return .run { send in
                    let settings = await userDefaultsClient.loadSettings()
                    await send(.settingsLoaded(settings))
                }

            case let .settingsLoaded(settings):
                state.settings = settings

                var effects: [Effect<Action>] = []

                // カスタムストレージのブックマーク解決と後続処理を順次実行
                effects.append(.run { [modelClient, userDefaultsClient] send in
                    // 1. カスタムストレージ場所を設定
                    if let bookmarkData = settings.transcription.storageBookmarkData {
                        if let url = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            await modelClient.setStorageLocation(url)
                        }
                    }

                    // 2. ストレージ設定完了後にダウンロード済みモデルを取得
                    await send(.fetchDownloadedModels)

                    // 3. ストレージ使用量とURL取得
                    let usage = await modelClient.getStorageUsage()
                    await send(.storageUsageResponse(usage))
                    let storageURL = await modelClient.getModelStorageURL()
                    await send(.modelStorageURLResponse(storageURL))
                })

                // 出力ディレクトリのブックマークを解決（独立して実行可能）
                if let outputBookmark = settings.output.outputBookmarkData {
                    effects.append(.run { [userDefaultsClient] send in
                        if let url = await userDefaultsClient.resolveBookmark(outputBookmark) {
                            await send(.outputDirectoryResolved(url))
                        }
                    })
                }

                return effects.isEmpty ? .none : .merge(effects)

            case let .outputBookmarkCreated(bookmarkData):
                state.settings.output.outputBookmarkData = bookmarkData
                return .none

            case let .outputDirectoryResolved(url):
                state.settings.output.outputDirectory = url
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
                return .run { [modelClient] send in
                    do {
                        let modelNames = try await modelClient.fetchAvailableModels()
                        let recommendedModel = await modelClient.recommendedModel()
                        var models: [WhisperModel] = []
                        for name in modelNames {
                            let isDownloaded = await modelClient.isModelDownloaded(name)
                            models.append(WhisperModel.from(
                                id: name,
                                isDownloaded: isDownloaded,
                                isRecommended: name == recommendedModel
                            ))
                        }
                        models.sort { $0.id < $1.id }
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

            case .fetchDownloadedModels:
                return .run { [modelClient] send in
                    do {
                        let models = try await modelClient.fetchDownloadedModelsAsWhisperModels()
                        await send(.downloadedModelsResponse(models))
                    } catch {
                        // エラー時は空のリストを返す（既存の動作を維持）
                        await send(.downloadedModelsResponse([]))
                    }
                }

            case let .downloadedModelsResponse(models):
                state.downloadedModels = models
                // 現在のモデルがダウンロード済みリストに含まれていない場合、最初のモデルを選択
                let currentModel = state.settings.transcription.modelName
                if !models.isEmpty, !models.contains(where: { $0.id == currentModel }) {
                    let newModel = models.first!.id
                    state.settings.transcription.modelName = newModel
                    return .merge(
                        .send(.saveSettings),
                        .send(.delegate(.modelChanged(newModel))),
                        .run { [modelClient] _ in
                            // 自動選択されたモデルを UserDefaults に保存
                            await modelClient.saveDefaultModel(newModel)
                        }
                    )
                }
                return .none

            case let .selectModel(modelName):
                state.settings.transcription.modelName = modelName

                // English-only モデルの場合は言語リストを英語と自動検出のみに制限
                if modelName.hasSuffix(".en") {
                    state.availableLanguages = TranscriptionLanguage.allSupported.filter {
                        $0.code == "auto" || $0.code == "en"
                    }
                    // 現在選択されている言語が英語でも自動検出でもない場合、自動検出にリセット
                    if state.settings.transcription.language.code != "auto",
                       state.settings.transcription.language.code != "en" {
                        state.settings.transcription.language = .auto
                    }
                } else {
                    // 多言語モデルの場合はすべての言語を表示
                    state.availableLanguages = TranscriptionLanguage.allSupported
                }

                return .merge(
                    .send(.saveSettings),
                    .send(.delegate(.modelChanged(modelName))),
                    .run { [modelClient] _ in
                        // デフォルトモデルを UserDefaults に保存
                        await modelClient.saveDefaultModel(modelName)
                        // AppDelegate にモデル変更を通知（メニューキャッシュを更新）
                        await MainActor.run {
                            NotificationCenter.default.post(name: .modelChanged, object: modelName)
                        }
                    }
                )

            case let .downloadModel(modelName):
                state.downloadingModelName = modelName
                state.downloadProgress[modelName] = 0
                return .run { [modelClient] send in
                    do {
                        let downloadedURL = try await modelClient.downloadModel(modelName) { progress in
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
                    return .merge(
                        .send(.calculateStorageUsage),
                        .send(.fetchDownloadedModels)
                    )
                case let .failure(error):
                    state.errorMessage = "ダウンロードに失敗しました: \(error.localizedDescription)"
                    return .none
                }

            case let .deleteModel(modelName):
                return .run { [modelClient] send in
                    do {
                        try await modelClient.deleteModel(modelName)
                        await send(.deleteModelResponse(modelName, .success(())))
                    } catch {
                        await send(.deleteModelResponse(modelName, .failure(error)))
                    }
                }

            case let .deleteModelButtonTapped(modelName):
                state.modelToDelete = modelName
                return .none

            case .confirmDeleteModel:
                guard let modelName = state.modelToDelete else { return .none }
                state.modelToDelete = nil
                return .send(.deleteModel(modelName))

            case .cancelDeleteModel:
                state.modelToDelete = nil
                return .none

            case let .deleteModelResponse(modelName, result):
                switch result {
                case .success:
                    if let index = state.availableModels.firstIndex(where: { $0.id == modelName }) {
                        state.availableModels[index].isDownloaded = false
                    }
                    return .merge(
                        .send(.calculateStorageUsage),
                        .send(.fetchDownloadedModels)
                    )
                case let .failure(error):
                    state.errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                    return .none
                }

            case .calculateStorageUsage:
                return .run { [modelClient] send in
                    let usage = await modelClient.getStorageUsage()
                    await send(.storageUsageResponse(usage))
                }

            case let .storageUsageResponse(usage):
                state.storageUsage = usage
                return .none

            case .fetchModelStorageURL:
                return .run { [modelClient] send in
                    let url = await modelClient.getModelStorageURL()
                    await send(.modelStorageURLResponse(url))
                }

            case let .modelStorageURLResponse(url):
                state.modelStorageURL = url
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
                    return .run { [settings = state.settings, modelClient, userDefaultsClient] send in
                        do {
                            let bookmarkData = try await userDefaultsClient.createBookmark(url)
                            var newSettings = settings
                            newSettings.transcription.customStorageURL = url
                            newSettings.transcription.storageBookmarkData = bookmarkData
                            await userDefaultsClient.saveStorageBookmark(bookmarkData)
                            await modelClient.setStorageLocation(url)
                            try await userDefaultsClient.saveSettings(newSettings)
                            await send(.settingsLoaded(newSettings))
                            await send(.calculateStorageUsage)
                            await send(.fetchModelStorageURL)
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
                return .run { [modelClient] send in
                    await modelClient.setStorageLocation(nil)
                    await send(.saveSettings)
                    await send(.fetchDownloadedModels)
                    await send(.calculateStorageUsage)
                    await send(.fetchModelStorageURL)
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

            case let .selectShortcut(shortcut):
                state.selectedShortcut = shortcut
                return .none

            case .fetchInputDevices:
                return .run { send in
                    let devices = await audioRecorder.fetchInputDevices()
                    await send(.inputDevicesResponse(devices))
                }

            case let .inputDevicesResponse(devices):
                state.availableInputDevices = devices
                return .none

            case .toggleAudioMonitoring:
                if state.isMonitoringAudio {
                    return .send(.stopAudioLevelObservation)
                } else {
                    return .send(.startAudioLevelObservation)
                }

            case .startAudioLevelObservation:
                state.isMonitoringAudio = true
                return .run { [audioRecorder] send in
                    do {
                        // モニタリングを開始
                        try await audioRecorder.startMonitoring()
                    } catch {
                        // モニタリング開始失敗時はログに記録
                        // observeAudioLevel()はデフォルト値(-60.0)を返す
                        Logger(subsystem: "com.whisperpad", category: "SettingsFeature")
                            .warning("Failed to start audio monitoring: \(error.localizedDescription)")
                    }

                    // モニタリングの成否に関わらず、レベル監視は継続
                    for await level in await audioRecorder.observeAudioLevel() {
                        await send(.audioLevelUpdated(level))
                    }
                }
                .cancellable(id: "audioLevelObservation")

            case .stopAudioLevelObservation:
                state.isMonitoringAudio = false
                state.currentAudioLevel = -60.0
                return .run { [audioRecorder] _ in
                    // モニタリングを停止
                    await audioRecorder.stopMonitoring()
                }
                .concatenate(with: .cancel(id: "audioLevelObservation"))

            case let .audioLevelUpdated(level):
                state.currentAudioLevel = level
                return .none

            case .checkHotkeyConflict:
                let hotKey = state.settings.hotKey
                let combos: [(String, HotKeySettings.KeyComboSettings)] = [
                    (HotkeyType.recording.displayName, hotKey.recordingHotKey),
                    (HotkeyType.cancel.displayName, hotKey.cancelHotKey),
                    (HotkeyType.recordingPause.displayName, hotKey.recordingPauseHotKey)
                ]

                var conflicts: [String] = []
                for index in 0 ..< combos.count {
                    for otherIndex in (index + 1) ..< combos.count {
                        let (name1, combo1) = combos[index]
                        let (name2, combo2) = combos[otherIndex]
                        if combo1.carbonKeyCode == combo2.carbonKeyCode,
                           combo1.carbonModifiers == combo2.carbonModifiers {
                            conflicts.append(name1 + String(localized: "hotkey.conflict.and", comment: " and ") + name2)
                        }
                    }
                }

                if conflicts.isEmpty {
                    state.hotkeyConflict = nil
                } else {
                    state.hotkeyConflict = String(
                        localized: "hotkey.conflict.prefix",
                        comment: "Conflict: "
                    ) + conflicts.joined(separator: ", ")
                }
                return .none

            case let .validateAndUpdateHotkey(type, newCombo):
                // 設定を更新する前に現在の値を保存（ロールバック用）
                state.previousHotKeySettings = state.settings.hotKey

                // アプリ内重複チェック（デフォルト設定との重複は許可）
                if let duplicateType = HotKeyValidator.findDuplicate(
                    carbonKeyCode: newCombo.carbonKeyCode,
                    carbonModifiers: newCombo.carbonModifiers,
                    currentType: type,
                    in: state.settings.hotKey
                ) {
                    // 重複検出 → アラート表示
                    return .send(.duplicateHotkeyDetected(type, duplicateWith: duplicateType))
                }

                // 仮更新（検証のため）
                updateHotkeySetting(&state.settings.hotKey, type: type, combo: newCombo)

                // Carbon APIでシステム競合を検証
                return .run { [settings = state.settings.hotKey] send in
                    let validation = HotKeyValidator.canRegister(
                        carbonKeyCode: newCombo.carbonKeyCode,
                        carbonModifiers: newCombo.carbonModifiers
                    )

                    switch validation {
                    case .success:
                        // 競合なし → 更新を確定
                        await send(.updateHotKeySettings(settings))
                    case .failure(.reservedSystemShortcut):
                        // システム予約済みショートカット → アラート表示
                        await send(.systemReservedShortcutDetected(type))
                    case .failure:
                        // システム競合あり → アラート表示
                        await send(.hotkeyConflictDetected(type))
                    }
                }

            case let .hotkeyConflictDetected(type):
                // 競合が検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.settings.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = type
                state.showHotkeyConflictAlert = true

                return .none

            case .dismissConflictAlert:
                state.showHotkeyConflictAlert = false
                state.conflictingHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case let .duplicateHotkeyDetected(targetType, duplicateType):
                // 重複が検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.settings.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = targetType
                state.duplicateWithHotkeyType = duplicateType
                state.showDuplicateHotkeyAlert = true

                return .none

            case .dismissDuplicateAlert:
                state.showDuplicateHotkeyAlert = false
                state.conflictingHotkeyType = nil
                state.duplicateWithHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case let .systemReservedShortcutDetected(type):
                // システム予約済みショートカットが検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.settings.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = type
                state.showSystemReservedAlert = true

                return .none

            case .dismissSystemReservedAlert:
                state.showSystemReservedAlert = false
                state.conflictingHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case .resetMenuBarIconSettings:
                state.settings.general.menuBarIconSettings = .default
                return .send(.saveSettings)

            case let .resetIconSetting(status):
                let defaultConfig = MenuBarIconSettings.default.config(for: status)
                state.settings.general.menuBarIconSettings.setConfig(defaultConfig, for: status)
                return .send(.saveSettings)

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Functions

/// HotKeySettingsの特定のhotkeyタイプを更新するヘルパー関数
private func updateHotkeySetting(
    _ hotKey: inout HotKeySettings,
    type: HotkeyType,
    combo: HotKeySettings.KeyComboSettings
) {
    switch type {
    case .recording:
        hotKey.recordingHotKey = combo
    case .cancel:
        hotKey.cancelHotKey = combo
    case .recordingPause:
        hotKey.recordingPauseHotKey = combo
    }
}
