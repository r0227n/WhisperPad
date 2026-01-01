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
        /// モデルが初期化済みかどうか
        var isModelInitialized: Bool = false
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
        /// モデルを初期化（必要な場合）
        case initializeModelIfNeeded
        /// モデル初期化が完了
        case modelInitialized
        /// モデル初期化に失敗
        case modelInitializationFailed(TranscriptionError)
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

                // WhisperKitClient の状態をチェック
                return .run { [isModelInitialized = state.isModelInitialized, whisperKitClient] send in
                    // WhisperKitManager が ready なら直接文字起こし開始
                    let isReady = await whisperKitClient.isReady()
                    if isReady || isModelInitialized {
                        await send(.performTranscription)
                    } else {
                        await send(.initializeModelIfNeeded)
                    }
                }

            case .initializeModelIfNeeded:
                state.status = .initializingModel
                logger.info("Initializing WhisperKit model...")

                return .run { [userDefaultsClient] send in
                    do {
                        let settings = await userDefaultsClient.loadSettings()
                        let modelName = settings.transcription.modelName
                        logger.info("Using model from settings: \(modelName)")
                        try await transcriptionClient.initialize(modelName)
                        await send(.modelInitialized)
                    } catch {
                        let transcriptionError =
                            (error as? TranscriptionError)
                                ?? .initializationFailed(error.localizedDescription)
                        await send(.modelInitializationFailed(transcriptionError))
                    }
                }

            case .modelInitialized:
                logger.info("WhisperKit model initialized successfully")
                state.isModelInitialized = true
                return .send(.performTranscription)

            case let .modelInitializationFailed(error):
                logger.error("Model initialization failed: \(error.localizedDescription)")
                state.status = .failed(error.localizedDescription)
                return .send(.delegate(.transcriptionFailed(error)))

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
