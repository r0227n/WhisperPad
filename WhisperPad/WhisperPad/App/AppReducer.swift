//
//  AppReducer.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation

/// アプリケーションのステータス
enum AppStatus: Equatable, Sendable {
    /// 待機中
    case idle
    /// 録音中
    case recording
    /// 一時停止中
    case paused
    /// 文字起こし中
    case transcribing
    /// 完了
    case completed
    /// エラー
    case error(String)
}

/// アプリケーション全体の状態を管理する TCA Reducer
///
/// アプリのステータス（idle, recording, transcribing, completed, error）を管理し、
/// 各状態に応じたアクションを処理します。
@Reducer
struct AppReducer {
    // MARK: - State

    /// アプリケーションの状態
    @ObservableState
    struct State: Equatable {
        /// 現在のアプリステータス
        var appStatus: AppStatus = .idle

        /// 最後の文字起こし結果
        var lastTranscription: String?

        /// 録音機能の状態
        var recording: RecordingFeature.State = .init()

        /// 文字起こし機能の状態
        var transcription: TranscriptionFeature.State = .init()

        /// 設定機能の状態
        var settings: SettingsFeature.State

        /// 最後に録音されたファイルの URL
        var lastRecordingURL: URL?

        /// モデルの状態
        var modelState: TranscriptionModelState = .unloaded

        /// 利用可能なモデル一覧（モデル名の配列）
        var availableModels: [String] = []

        /// 現在読み込まれているモデル名
        var currentModelName: String?

        /// 初期化
        ///
        /// - Parameters:
        ///   - appStatus: アプリステータス（デフォルト: .idle）
        ///   - lastTranscription: 最後の文字起こし結果
        ///   - recording: 録音機能の状態
        ///   - transcription: 文字起こし機能の状態
        ///   - settings: 設定機能の状態
        ///   - lastRecordingURL: 最後に録音されたファイルの URL
        ///   - modelState: モデルの状態
        ///   - availableModels: 利用可能なモデル一覧
        ///   - currentModelName: 現在のモデル名
        init(
            appStatus: AppStatus = .idle,
            lastTranscription: String? = nil,
            recording: RecordingFeature.State = .init(),
            transcription: TranscriptionFeature.State = .init(),
            settings: SettingsFeature.State = .init(),
            lastRecordingURL: URL? = nil,
            modelState: TranscriptionModelState = .unloaded,
            availableModels: [String] = [],
            currentModelName: String? = nil
        ) {
            self.appStatus = appStatus
            self.lastTranscription = lastTranscription
            self.recording = recording
            self.transcription = transcription
            self.settings = settings
            self.lastRecordingURL = lastRecordingURL
            self.modelState = modelState
            self.availableModels = availableModels
            self.currentModelName = currentModelName
        }
    }

    // MARK: - Action

    /// アプリケーションのアクション
    enum Action {
        /// 録音を開始
        case startRecording
        /// 録音を終了
        case endRecording
        /// 録音を一時停止
        case pauseRecording
        /// 録音を再開
        case resumeRecording
        /// 録音をキャンセル
        case cancelRecording
        /// 文字起こしが完了
        case transcriptionCompleted(String)
        /// エラーが発生
        case errorOccurred(String)
        /// 待機状態にリセット
        case resetToIdle
        /// 録音機能のアクション
        case recording(RecordingFeature.Action)
        /// 文字起こし機能のアクション
        case transcription(TranscriptionFeature.Action)
        /// 設定機能のアクション
        case settings(SettingsFeature.Action)
        /// 利用可能なモデル一覧を取得
        case fetchAvailableModels
        /// モデル一覧取得完了
        case modelsLoaded([String])
        /// モデルを選択
        case selectModel(String)
        /// モデル状態を更新
        case modelStateUpdated(TranscriptionModelState)
        /// 現在のモデル名を更新
        case currentModelNameUpdated(String?)
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock
    @Dependency(\.outputClient) var outputClient
    @Dependency(\.whisperKitClient) var whisperKitClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.transcriptionClient) var transcriptionClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { (state: inout State, action: Action) -> Effect<Action> in
            switch action {
            case .startRecording:
                // 録音機能に委譲
                return .send(.recording(.startRecordingButtonTapped))

            case .endRecording:
                // 録音機能に委譲
                return .send(.recording(.endRecordingButtonTapped))

            case .pauseRecording:
                // 録音機能に委譲
                return .send(.recording(.pauseRecordingButtonTapped))

            case .resumeRecording:
                // 録音機能に委譲
                return .send(.recording(.resumeRecordingButtonTapped))

            case .cancelRecording:
                // 録音機能に委譲
                return .send(.recording(.cancelRecordingButtonTapped))

            // RecordingFeature のデリゲートアクションを処理
            case let .recording(.delegate(.recordingCompleted(url))):
                state.appStatus = .transcribing
                state.lastRecordingURL = url
                // TranscriptionFeature に文字起こしを委譲（設定から言語を取得）
                let language = state.settings.settings.transcription.language.whisperCode
                return .send(.transcription(.startTranscription(audioURL: url, language: language)))

            case .recording(.delegate(.recordingCancelled)):
                state.appStatus = .idle
                return .none

            case let .recording(.delegate(.recordingFailed(error))):
                state.appStatus = .error(error.localizedDescription)
                let languageCode = state.resolveLanguageCode()
                let iconSettings = state.settings.settings.general.menuBarIconSettings

                return .run { send in
                    await MainActor.run {
                        showLocalizedAlert(
                            style: .critical,
                            titleKey: "error.dialog.recording.title",
                            message: error.localizedDescription,
                            languageCode: languageCode,
                            iconSettings: iconSettings
                        )
                    }
                    try await clock.sleep(for: .seconds(5))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case let .recording(.delegate(.recordingPartialSuccess(url, usedSegments, totalSegments))):
                state.appStatus = .transcribing
                state.lastRecordingURL = url
                // ダイアログ表示後に文字起こしを開始（設定から言語を取得）
                let partialLanguage = state.settings.settings.transcription.language.whisperCode
                let languageCode = state.resolveLanguageCode()
                let iconSettings = state.settings.settings.general.menuBarIconSettings

                return .run { send in
                    await MainActor.run {
                        let messageFormat = Bundle.main.localizedString(
                            forKey: "recording.partial_success.alert.message",
                            preferredLanguage: languageCode
                        )
                        let formattedMessage = String(format: messageFormat, usedSegments, totalSegments)

                        showLocalizedAlert(
                            style: .warning,
                            titleKey: "recording.partial_success.alert.title",
                            message: formattedMessage,
                            languageCode: languageCode,
                            iconSettings: iconSettings
                        )
                    }
                    await send(.transcription(.startTranscription(audioURL: url, language: partialLanguage)))
                }

            case .recording(.delegate(.whisperKitInitializing)):
                // WhisperKit初期化中のアラートを表示
                let languageCode = state.resolveLanguageCode()
                let iconSettings = state.settings.settings.general.menuBarIconSettings

                return .run { _ in
                    await MainActor.run {
                        let message = Bundle.main.localizedString(
                            forKey: "recording.whisperkit_initializing.alert.message",
                            preferredLanguage: languageCode
                        )

                        showLocalizedAlert(
                            style: .informational,
                            titleKey: "recording.whisperkit_initializing.alert.title",
                            message: message,
                            languageCode: languageCode,
                            iconSettings: iconSettings
                        )
                    }
                }

            // RecordingFeature の内部アクションで appStatus を更新
            case .recording(.recordingStarted):
                state.appStatus = .recording
                return .cancel(id: "autoReset")

            case .recording(.prepareRecording):
                state.appStatus = .recording
                return .cancel(id: "autoReset")

            case .recording(.recordingPaused):
                state.appStatus = .paused
                return .none

            case .recording(.recordingResumed):
                state.appStatus = .recording
                return .none

            case .recording:
                // その他の録音アクションは無視
                return .none

            // TranscriptionFeature のデリゲートアクションを処理
            case let .transcription(.delegate(.transcriptionCompleted(text))):
                return .send(.transcriptionCompleted(text))

            case let .transcription(.delegate(.transcriptionFailed(error))):
                return .send(.errorOccurred(error.localizedDescription))

            case .transcription:
                // その他の文字起こしアクションは無視
                return .none

            // SettingsFeature のデリゲートアクションを処理
            case .settings(.delegate(.modelChanged)):
                // モデルが変更された場合、WhisperKitをアンロード（次回使用時に新モデルで初期化）
                return .run { [whisperKitClient] _ in
                    await whisperKitClient.unload()
                }

            case .settings(.delegate(.settingsChanged)):
                // アイドルタイムアウト設定をWhisperKitManagerに反映
                let generalSettings = state.settings.settings.general
                return .run { [whisperKitClient] _ in
                    await whisperKitClient.configureIdleTimeout(
                        generalSettings.whisperKitIdleTimeoutEnabled,
                        generalSettings.whisperKitIdleTimeoutMinutes
                    )
                }

            case .settings:
                // その他の設定アクションは無視
                return .none

            case let .transcriptionCompleted(text):
                state.appStatus = .completed
                state.lastTranscription = text
                let outputSettings = state.settings.settings.output
                let generalSettings = state.settings.settings.general
                let notificationTitle = generalSettings.notificationTitle.isEmpty
                    ? String(localized: "notification.default.title")
                    : generalSettings.notificationTitle
                let transcriptionCompleteMessage = generalSettings.transcriptionCompleteMessage.isEmpty
                    ? String(localized: "notification.transcription.complete.message")
                    : generalSettings.transcriptionCompleteMessage

                return .run { [outputClient, userDefaultsClient] send in
                    // クリップボードにコピー（設定が有効な場合）
                    if outputSettings.copyToClipboard {
                        _ = await outputClient.copyToClipboard(text)
                    }

                    // 自動ファイル出力が有効な場合
                    if outputSettings.isEnabled {
                        var resolvedOutputSettings = outputSettings

                        // ブックマークを解決してアクセス権を取得
                        if let bookmarkData = outputSettings.outputBookmarkData,
                           let resolvedURL = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            resolvedOutputSettings.outputDirectory = resolvedURL
                        }

                        do {
                            let url = try await outputClient.saveToFile(text, resolvedOutputSettings)
                            if generalSettings.showNotificationOnComplete {
                                await outputClient.showNotification(
                                    notificationTitle,
                                    String(
                                        format: String(localized: "notification.file.save.success"),
                                        url.lastPathComponent
                                    )
                                )
                            }
                        } catch {
                            if generalSettings.showNotificationOnComplete {
                                await outputClient.showNotification(
                                    notificationTitle,
                                    String(
                                        format: String(localized: "notification.file.save.failure"),
                                        error.localizedDescription
                                    )
                                )
                            }
                        }
                    } else {
                        if generalSettings.showNotificationOnComplete {
                            await outputClient.showNotification(
                                notificationTitle,
                                transcriptionCompleteMessage
                            )
                        }
                    }

                    // 完了音を再生（設定が有効な場合）
                    if generalSettings.playSoundOnComplete {
                        await outputClient.playCompletionSound()
                    }

                    // 自動リセット
                    try await clock.sleep(for: .seconds(3))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case let .errorOccurred(message):
                state.appStatus = .error(message)
                let languageCode = state.resolveLanguageCode()
                let iconSettings = state.settings.settings.general.menuBarIconSettings

                return .run { send in
                    await MainActor.run {
                        showLocalizedAlert(
                            style: .critical,
                            titleKey: "error.dialog.general.title",
                            message: message,
                            languageCode: languageCode,
                            iconSettings: iconSettings
                        )
                    }
                    try await clock.sleep(for: .seconds(5))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case .resetToIdle:
                state.appStatus = .idle
                return .none

            case .fetchAvailableModels:
                return .run { [transcriptionClient] send in
                    do {
                        let modelNames = try await transcriptionClient.fetchAvailableModels()
                        await send(.modelsLoaded(modelNames))
                    } catch {
                        // エラー時は空のリストを設定
                        await send(.modelsLoaded([]))
                    }
                }

            case let .modelsLoaded(models):
                state.availableModels = models
                return .none

            case let .selectModel(modelName):
                // 設定機能に委譲
                return .send(.settings(.selectModel(modelName)))

            case let .modelStateUpdated(modelState):
                state.modelState = modelState
                return .none

            case let .currentModelNameUpdated(modelName):
                state.currentModelName = modelName
                return .none
            }
        }

        // 録音機能の子 Reducer を統合
        Scope(state: \.recording, action: \.recording) {
            RecordingFeature()
        }

        // 文字起こし機能の子 Reducer を統合
        Scope(state: \.transcription, action: \.transcription) {
            TranscriptionFeature()
        }

        // 設定機能の子 Reducer を統合
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
    }
}

// MARK: - Alert Helpers

private extension AppReducer.State {
    /// アプリ設定から言語コードを解決する
    /// - Returns: 言語コード文字列（例: "en", "ja"）
    func resolveLanguageCode() -> String {
        let preferredLocale = settings.settings.general.preferredLocale
        if let identifier = preferredLocale.identifier {
            return identifier
        } else {
            // .system の場合、システムの優先言語を使用
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            return Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
        }
    }
}

// MARK: - Localization Helpers

/// xcstrings ファイルから指定されたロケールに基づいて翻訳を取得する
private extension Bundle {
    func localizedString(forKey key: String, preferredLanguage: String) -> String {
        // For xcstrings files, try to get bundle for preferred language
        if let path = self.path(forResource: preferredLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }

        // Fallback to main bundle (will use sourceLanguage from xcstrings)
        return self.localizedString(forKey: key, value: nil, table: nil)
    }
}
