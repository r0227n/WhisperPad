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

        /// エラーメッセージ
        var errorMessage: String?

        /// 設定を保存中かどうか
        var isSaving: Bool = false

        /// ホットキー録音中のタイプ（nil = 録音なし）
        var recordingHotkeyType: HotkeyType?

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

        /// 選択中のショートカット（ホットキー設定タブ用）
        var selectedShortcut: HotkeyType?

        /// 録音設定子Feature用のState
        var recordingSettings: RecordingSettingsFeature.State = .init()

        /// 一般設定子Feature用のState
        var generalSettings: GeneralSettingsFeature.State = .init()

        /// ホットキー設定子Feature用のState
        var hotkeySettings: HotkeySettingsFeature.State = .init()

        /// アイコン設定子Feature用のState
        var iconSettings: IconSettingsFeature.State = .init()

        /// モデル設定子Feature用のState
        var modelSettings: ModelSettingsFeature.State = .init()

        // MARK: - Computed Properties for backward compatibility

        /// 利用可能な入力デバイス一覧（RecordingSettingsFeatureから取得）
        var availableInputDevices: [AudioInputDevice] {
            recordingSettings.availableInputDevices
        }

        /// 現在の音声レベル（dB）（RecordingSettingsFeatureから取得）
        var currentAudioLevel: Float {
            recordingSettings.currentAudioLevel
        }

        /// 音声レベル監視中かどうか（RecordingSettingsFeatureから取得）
        var isMonitoringAudio: Bool {
            recordingSettings.isMonitoringAudio
        }
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

        // MARK: - Child Feature

        /// 録音設定子Feature
        case recordingSettings(RecordingSettingsFeature.Action)
        /// 一般設定子Feature
        case generalSettings(GeneralSettingsFeature.Action)
        /// ホットキー設定子Feature
        case hotkeySettings(HotkeySettingsFeature.Action)
        /// アイコン設定子Feature
        case iconSettings(IconSettingsFeature.Action)
        /// モデル設定子Feature
        case modelSettings(ModelSettingsFeature.Action)

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
        // 子Reducerをスコープ
        Scope(state: \.recordingSettings, action: \.recordingSettings) {
            RecordingSettingsFeature()
        }
        Scope(state: \.generalSettings, action: \.generalSettings) {
            GeneralSettingsFeature()
        }
        Scope(state: \.hotkeySettings, action: \.hotkeySettings) {
            HotkeySettingsFeature()
        }
        Scope(state: \.iconSettings, action: \.iconSettings) {
            IconSettingsFeature()
        }
        Scope(state: \.modelSettings, action: \.modelSettings) {
            ModelSettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadSettings),
                    .send(.recordingSettings(.fetchInputDevices)),
                    .send(.checkHotkeyConflict)
                )

            case .onDisappear:
                // 音声レベル監視が有効な場合は停止
                if state.isMonitoringAudio {
                    return .send(.recordingSettings(.stopAudioLevelObservation))
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

                // ModelSettingsFeature の State を初期化
                state.modelSettings.transcription = settings.transcription
                state.modelSettings.preferredLocale = settings.general.preferredLocale

                var effects: [Effect<Action>] = []

                // カスタムストレージのブックマーク解決
                if let bookmarkData = settings.transcription.storageBookmarkData {
                    effects.append(.run { [modelClient, userDefaultsClient] _ in
                        if let url = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            await modelClient.setStorageLocation(url)
                        }
                    })
                }

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
                // RecordingSettingsFeature経由で処理
                return .send(.recordingSettings(.fetchInputDevices))

            case .inputDevicesResponse:
                // RecordingSettingsFeatureで処理済みなので何もしない
                return .none

            case .toggleAudioMonitoring:
                // RecordingSettingsFeature経由で処理
                return .send(.recordingSettings(.toggleAudioMonitoring))

            case .startAudioLevelObservation:
                // RecordingSettingsFeature経由で処理
                return .send(.recordingSettings(.startAudioLevelObservation))

            case .stopAudioLevelObservation:
                // RecordingSettingsFeature経由で処理
                return .send(.recordingSettings(.stopAudioLevelObservation))

            case .audioLevelUpdated:
                // RecordingSettingsFeatureで処理済みなので何もしない
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
                if let duplicateType = HotKeyClient.findDuplicate(
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
                    let validation = HotKeyClient.canRegister(
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

            // MARK: - Child Feature Delegates

            case .recordingSettings:
                // RecordingSettingsFeatureは独自のDelegateを持たないため、何もしない
                return .none

            case let .generalSettings(.delegate(.generalSettingsChanged(general))):
                state.settings.general = general
                return .send(.saveSettings)

            case .generalSettings:
                return .none

            case let .hotkeySettings(.delegate(.hotKeySettingsChanged(hotKey))):
                state.settings.hotKey = hotKey
                // ホットキー設定変更を通知（AppDelegateでホットキーを再登録）
                NotificationCenter.default.post(
                    name: .hotKeySettingsChanged,
                    object: hotKey
                )
                return .send(.saveSettings)

            case .hotkeySettings:
                return .none

            case let .iconSettings(.delegate(.iconSettingsChanged(iconSettings))):
                state.settings.general.menuBarIconSettings = iconSettings
                return .send(.saveSettings)

            case .iconSettings:
                return .none

            case let .modelSettings(.delegate(.modelSelected(modelName))):
                state.settings.transcription.modelName = modelName
                return .merge(
                    .send(.saveSettings),
                    .send(.delegate(.modelChanged(modelName)))
                )

            case let .modelSettings(.delegate(.transcriptionSettingsChanged(transcription))):
                state.settings.transcription = transcription
                return .send(.saveSettings)

            case .modelSettings:
                return .none

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
