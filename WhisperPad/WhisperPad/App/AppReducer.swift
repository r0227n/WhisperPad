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
        /// 録音キャンセルの確認
        case confirmCancelRecording
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
    @Dependency(\.modelClient) var modelClient

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
                return handleCancelRecording(state: &state)

            case .confirmCancelRecording:
                // 実際のキャンセル処理を実行
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
                return handlePartialSuccess(
                    url: url,
                    usedSegments: usedSegments,
                    totalSegments: totalSegments,
                    state: state
                )

            case .recording(.delegate(.whisperKitInitializing)):
                return handleWhisperKitInitializing(state: state)

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
                return handleTranscriptionCompleted(text: text, state: state)

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
                return .run { [modelClient] send in
                    do {
                        let modelNames = try await modelClient.fetchAvailableModels()
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

// MARK: - State Helpers

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

// MARK: - Helper Methods

private extension AppReducer {
    func handleCancelRecording(state: inout State) -> Effect<Action> {
        let showConfirmation = state.settings.settings.general.showCancelConfirmation

        if showConfirmation {
            let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)
            var currentGeneral = state.settings.settings.general

            return .run { send in
                let (shouldCancel, dontShowAgain) = await AppAlertHelper.showCancelConfirmationDialog(
                    languageCode: languageCode
                )

                if dontShowAgain {
                    currentGeneral.showCancelConfirmation = false
                    await send(.settings(.updateGeneralSettings(currentGeneral)))
                }

                if shouldCancel {
                    await send(.confirmCancelRecording)
                }
            }
        } else {
            return .send(.confirmCancelRecording)
        }
    }

    func handlePartialSuccess(
        url: URL,
        usedSegments: Int,
        totalSegments: Int,
        state: State
    ) -> Effect<Action> {
        let language = state.settings.settings.transcription.language.whisperCode
        let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)

        return .run { send in
            await AppAlertHelper.showPartialSuccessDialog(
                usedSegments: usedSegments,
                totalSegments: totalSegments,
                languageCode: languageCode
            )
            await send(.transcription(.startTranscription(audioURL: url, language: language)))
        }
    }

    func handleWhisperKitInitializing(state: State) -> Effect<Action> {
        let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)

        return .run { _ in
            await AppAlertHelper.showWhisperKitInitializingDialog(languageCode: languageCode)
        }
    }

    func handleTranscriptionCompleted(text: String, state: State) -> Effect<Action> {
        let outputSettings = state.settings.settings.output
        let generalSettings = state.settings.settings.general

        return .run { [outputClient, userDefaultsClient, clock] send in
            if outputSettings.copyToClipboard {
                _ = await outputClient.copyToClipboard(text)
            }

            await handleOutputAndNotification(
                text: text,
                outputSettings: outputSettings,
                generalSettings: generalSettings,
                outputClient: outputClient,
                userDefaultsClient: userDefaultsClient
            )

            if generalSettings.playSoundOnComplete {
                await outputClient.playCompletionSound()
            }

            try await clock.sleep(for: .seconds(3))
            await send(.resetToIdle)
        }
        .cancellable(id: "autoReset")
    }

    func handleOutputAndNotification(
        text: String,
        outputSettings: FileOutputSettings,
        generalSettings: GeneralSettings,
        outputClient: OutputClient,
        userDefaultsClient: UserDefaultsClient
    ) async {
        let notificationTitle = generalSettings.notificationTitle.isEmpty
            ? String(localized: "notification.default.title")
            : generalSettings.notificationTitle
        let transcriptionCompleteMessage = generalSettings.transcriptionCompleteMessage.isEmpty
            ? String(localized: "notification.transcription.complete.message")
            : generalSettings.transcriptionCompleteMessage

        if outputSettings.isEnabled {
            var resolvedOutputSettings = outputSettings

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
    }

    func getLanguageCode(from preferredLocale: AppLocale) -> String {
        if let identifier = preferredLocale.identifier {
            return identifier
        } else {
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            return Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
        }
    }
}
