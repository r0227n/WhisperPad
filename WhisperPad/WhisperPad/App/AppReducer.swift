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
        var settings: SettingsFeature.State = .init()

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
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock
    @Dependency(\.outputClient) var outputClient

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
                // ダイアログ表示後に文字起こしを開始
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
                    await send(.transcription(.startTranscription(audioURL: url, language: nil)))
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
                // モデルが変更された場合、TranscriptionFeature を再初期化
                state.transcription.isModelInitialized = false
                return .none

            case .settings(.delegate(.settingsChanged)):
                // 設定が変更された場合の処理（必要に応じて）
                return .none

            case .settings:
                // その他の設定アクションは無視
                return .none

            case let .transcriptionCompleted(text):
                state.appStatus = .completed
                state.lastTranscription = text
                return .run { [outputClient] send in
                    // クリップボードにコピー
                    _ = await outputClient.copyToClipboard(text)

                    // 通知を表示
                    await outputClient.showNotification(
                        "WhisperPad",
                        "文字起こしが完了しました"
                    )

                    // 完了音を再生
                    await outputClient.playCompletionSound()

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
