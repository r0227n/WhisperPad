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
    /// ストリーミング文字起こし中
    case streamingTranscribing
    /// ストリーミング完了
    case streamingCompleted
    /// エラー
    case error(String)
}

/// WhisperKit の初期化ステータス
enum WhisperKitInitStatus: Equatable, Sendable {
    /// 未開始
    case notStarted
    /// 初期化中
    case initializing
    /// 準備完了
    case ready
    /// 失敗
    case failed(String)
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

        /// WhisperKit の初期化ステータス
        var whisperKitStatus: WhisperKitInitStatus = .notStarted

        /// 最後の文字起こし結果
        var lastTranscription: String?

        /// 録音機能の状態
        var recording: RecordingFeature.State = .init()

        /// 文字起こし機能の状態
        var transcription: TranscriptionFeature.State = .init()

        /// 設定機能の状態
        var settings: SettingsFeature.State = .init()

        /// ストリーミング文字起こし機能の状態
        var streamingTranscription: StreamingTranscriptionFeature.State = .init()

        /// 最後に録音されたファイルの URL
        var lastRecordingURL: URL?
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
        /// ストリーミング文字起こしを開始
        case startStreamingTranscription
        /// ストリーミング文字起こし機能のアクション
        case streamingTranscription(StreamingTranscriptionFeature.Action)
        /// WhisperKit を初期化
        case initializeWhisperKit
        /// WhisperKit 初期化完了
        case whisperKitInitCompleted
        /// WhisperKit 初期化失敗
        case whisperKitInitFailed(String)
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock
    @Dependency(\.outputClient) var outputClient
    @Dependency(\.whisperKitClient) var whisperKitClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
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
                return .run { send in
                    try await clock.sleep(for: .seconds(5))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case let .recording(.delegate(.recordingPartialSuccess(url, usedSegments, totalSegments))):
                state.appStatus = .transcribing
                state.lastRecordingURL = url
                // ダイアログ表示後に文字起こしを開始（設定から言語を取得）
                let partialLanguage = state.settings.settings.transcription.language.whisperCode
                return .run { send in
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.alertStyle = .warning
                        alert.messageText = "録音の一部が保存されました"
                        alert.informativeText = """
                        音声ファイルの結合に失敗したため、\
                        最初のセグメント（\(usedSegments)/\(totalSegments)）のみが保存されました。
                        一時停止後の録音内容は失われています。
                        """
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                    await send(.transcription(.startTranscription(audioURL: url, language: partialLanguage)))
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
                // モデルが変更された場合、WhisperKit を再初期化
                state.whisperKitStatus = .notStarted
                state.transcription.isModelInitialized = false
                return .send(.initializeWhisperKit)

            case .settings(.delegate(.settingsChanged)):
                // 設定が変更された場合の処理（必要に応じて）
                return .none

            case .settings:
                // その他の設定アクションは無視
                return .none

            // MARK: - Streaming Transcription

            case .startStreamingTranscription:
                // 既存のストリーミング状態をリセット
                state.streamingTranscription.status = .idle
                state.streamingTranscription.confirmedText = ""
                state.streamingTranscription.pendingText = ""
                state.streamingTranscription.decodingText = ""
                state.streamingTranscription.duration = 0
                state.streamingTranscription.tokensPerSecond = 0
                state.streamingTranscription.showCancelConfirmation = false
                // ストリーミング文字起こし機能に委譲
                return .send(.streamingTranscription(.startButtonTapped))

            // StreamingTranscriptionFeature のデリゲートアクションを処理
            case let .streamingTranscription(.delegate(.streamingCompleted(text))):
                // appStatusはfinalizationCompletedで既に.streamingCompletedに設定済み
                state.lastTranscription = text
                let copyToClipboard = state.settings.settings.output.copyToClipboard
                let generalSettings = state.settings.settings.general

                return .run { [outputClient, clock] send in
                    // 通知を表示（設定が有効な場合）
                    if generalSettings.showNotificationOnComplete {
                        await outputClient.showNotification(
                            "WhisperPad",
                            "リアルタイム文字起こしが完了しました"
                        )
                    }

                    // 完了音を再生（設定が有効な場合）
                    if generalSettings.playSoundOnComplete {
                        await outputClient.playCompletionSound()
                    }

                    // クリップボードにコピー（設定が有効な場合）
                    if copyToClipboard {
                        _ = await outputClient.copyToClipboard(text)
                    }

                    // 自動リセット
                    try await clock.sleep(for: .seconds(3))
                    await send(.resetToIdle)
                }

            case .streamingTranscription(.delegate(.streamingCancelled)):
                state.appStatus = .idle
                // AppDelegate にポップアップを閉じる通知を送信
                return .run { _ in
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .closeStreamingPopup,
                            object: nil
                        )
                    }
                }

            case .streamingTranscription(.delegate(.closePopup)):
                // 状態をリセット
                state.appStatus = .idle
                state.streamingTranscription.status = .idle
                state.streamingTranscription.confirmedText = ""
                state.streamingTranscription.pendingText = ""
                state.streamingTranscription.decodingText = ""
                state.streamingTranscription.duration = 0
                state.streamingTranscription.tokensPerSecond = 0
                // AppDelegate にポップアップを閉じる通知を送信
                return .run { _ in
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .closeStreamingPopup,
                            object: nil
                        )
                    }
                }

            // StreamingTranscriptionFeature の内部アクションで appStatus を更新
            case .streamingTranscription(.startButtonTapped):
                // 初期化中はギアアニメーションを表示
                state.appStatus = .transcribing
                return .none

            case .streamingTranscription(.initializationCompleted):
                state.appStatus = .streamingTranscribing
                return .none

            case let .streamingTranscription(.initializationFailed(message)):
                state.appStatus = .error(message)
                return .none

            case .streamingTranscription(.stopButtonTapped):
                // 処理中（ファイナライズ中）はギアアニメーションを表示
                state.appStatus = .transcribing
                return .none

            case .streamingTranscription(.finalizationCompleted):
                // ファイナライズ完了時にアイコンを完了状態に
                state.appStatus = .streamingCompleted
                return .none

            case let .streamingTranscription(.finalizationFailed(message)):
                state.appStatus = .error(message)
                return .none

            case .streamingTranscription:
                // その他のストリーミングアクションは無視
                return .none

            case let .transcriptionCompleted(text):
                state.appStatus = .completed
                state.lastTranscription = text
                let outputSettings = state.settings.settings.output
                let generalSettings = state.settings.settings.general
                let notificationTitle = generalSettings.notificationTitle
                let transcriptionCompleteMessage = generalSettings.transcriptionCompleteMessage

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
                                    "WhisperPad",
                                    "保存完了: \(url.lastPathComponent)"
                                )
                            }
                        } catch {
                            if generalSettings.showNotificationOnComplete {
                                await outputClient.showNotification(
                                    "WhisperPad",
                                    "ファイル保存に失敗: \(error.localizedDescription)"
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
                return .run { send in
                    try await clock.sleep(for: .seconds(5))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case .resetToIdle:
                state.appStatus = .idle
                state.streamingTranscription.status = .idle
                state.streamingTranscription.confirmedText = ""
                state.streamingTranscription.pendingText = ""
                state.streamingTranscription.decodingText = ""
                state.streamingTranscription.duration = 0
                state.streamingTranscription.tokensPerSecond = 0
                return .none

            // MARK: - WhisperKit Initialization

            case .initializeWhisperKit:
                // 既に初期化中または完了済みの場合はスキップ
                guard state.whisperKitStatus == .notStarted
                    || state.whisperKitStatus != .initializing
                else {
                    return .none
                }
                state.whisperKitStatus = .initializing

                return .run { [userDefaultsClient, whisperKitClient] send in
                    do {
                        // 設定からモデル名を取得
                        let settings = await userDefaultsClient.loadSettings()
                        let modelName = settings.transcription.modelName

                        try await whisperKitClient.initialize(modelName)
                        await send(.whisperKitInitCompleted)
                    } catch {
                        await send(.whisperKitInitFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: "whisperKitInit")

            case .whisperKitInitCompleted:
                state.whisperKitStatus = .ready
                state.transcription.isModelInitialized = true
                return .none

            case let .whisperKitInitFailed(message):
                state.whisperKitStatus = .failed(message)
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

        // ストリーミング文字起こし機能の子 Reducer を統合
        Scope(state: \.streamingTranscription, action: \.streamingTranscription) {
            StreamingTranscriptionFeature()
        }
    }
}
