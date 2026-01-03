//
//  TranscriptionFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "TranscriptionFeature")

/// 文字起こし機能の TCA Reducer
///
/// 録音した音声ファイルを WhisperKit で文字起こしするライフサイクルを管理します。
@Reducer
struct TranscriptionFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 現在の文字起こしステータス
        var status: Status = .idle
        /// 最後の文字起こし結果
        var lastResult: String?
        /// 処理中の音声ファイル URL
        var currentAudioURL: URL?
        /// 処理中の言語設定
        var currentLanguage: String?
    }

    // MARK: - Action

    enum Action: Sendable {
        // 内部アクション
        /// 文字起こしを開始
        case startTranscription(audioURL: URL, language: String?)
        /// 文字起こしを実行
        case performTranscription
        /// 文字起こし結果
        case transcriptionResult(String)
        /// 文字起こしに失敗
        case transcriptionFailed(TranscriptionError)
        /// 状態をリセット
        case reset

        // デリゲートアクション（親 Reducer への通知）
        /// デリゲートアクション
        case delegate(Delegate)
    }

    // MARK: - Dependencies

    @Dependency(\.transcriptionClient) var transcriptionClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.whisperKitClient) var whisperKitClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .startTranscription(audioURL, language):
                logger.info("Starting transcription for: \(audioURL.lastPathComponent)")
                state.status = .idle
                state.currentAudioURL = audioURL
                state.currentLanguage = language

                // 直接文字起こしを実行（WhisperKitの初期化は録音/ストリーミング開始時に完了している）
                return .send(.performTranscription)

            case .performTranscription:
                guard let audioURL = state.currentAudioURL else {
                    let error = TranscriptionError.audioLoadFailed("No audio URL provided")
                    return .send(.transcriptionFailed(error))
                }

                state.status = .transcribing
                logger.info("Performing transcription...")

                return .run { [language = state.currentLanguage] send in
                    do {
                        let result = try await transcriptionClient.transcribe(audioURL, language)
                        await send(.transcriptionResult(result))
                    } catch {
                        let transcriptionError =
                            (error as? TranscriptionError)
                                ?? .transcriptionFailed(error.localizedDescription)
                        await send(.transcriptionFailed(transcriptionError))
                    }
                }

            case let .transcriptionResult(text):
                logger.info("Transcription completed: \(text.prefix(50))...")
                state.status = .completed
                state.lastResult = text
                state.currentAudioURL = nil
                state.currentLanguage = nil
                return .send(.delegate(.transcriptionCompleted(text)))

            case let .transcriptionFailed(error):
                logger.error("Transcription failed: \(error.localizedDescription)")
                state.status = .failed(error.localizedDescription)
                state.currentAudioURL = nil
                state.currentLanguage = nil
                return .send(.delegate(.transcriptionFailed(error)))

            case .reset:
                state.status = .idle
                state.lastResult = nil
                state.currentAudioURL = nil
                state.currentLanguage = nil
                return .none

            case .delegate:
                // 親 Reducer で処理
                return .none
            }
        }
    }
}

// MARK: - Nested Types

extension TranscriptionFeature {
    /// 文字起こしステータス
    enum Status: Equatable, Sendable {
        /// 待機中
        case idle
        /// モデル初期化中
        case initializingModel
        /// 文字起こし中
        case transcribing
        /// 完了
        case completed
        /// 失敗
        case failed(String)
    }

    /// デリゲートアクション（親 Reducer への通知）
    enum Delegate: Sendable, Equatable {
        /// 文字起こしが完了
        case transcriptionCompleted(String)
        /// 文字起こしに失敗
        case transcriptionFailed(TranscriptionError)
    }
}
