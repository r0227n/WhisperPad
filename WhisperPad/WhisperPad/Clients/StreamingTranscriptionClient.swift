//
//  StreamingTranscriptionClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "StreamingTranscriptionClient")

/// ストリーミング文字起こしクライアント
///
/// WhisperKit を使用してリアルタイム文字起こしを提供します。
struct StreamingTranscriptionClient: Sendable {
    /// WhisperKit を初期化
    var initialize: @Sendable (_ modelName: String?) async throws -> Void

    /// 音声チャンクを処理
    var processChunk: @Sendable (_ samples: [Float]) async throws -> TranscriptionProgress

    /// 文字起こしを終了し、最終結果を返す
    var finalize: @Sendable () async throws -> String

    /// 状態をリセット
    var reset: @Sendable () async -> Void
}

// MARK: - DependencyKey

extension StreamingTranscriptionClient: DependencyKey {
    private static let service = StreamingTranscriptionService()

    static var liveValue: Self {
        Self(
            initialize: { modelName in
                try await service.initialize(modelName: modelName)
            },
            processChunk: { samples in
                try await service.processAudioChunk(samples)
            },
            finalize: {
                try await service.finalize()
            },
            reset: {
                await service.reset()
            }
        )
    }
}

// MARK: - TestDependencyKey

extension StreamingTranscriptionClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[PREVIEW] initialize called with \(modelName ?? "nil")")
            },
            processChunk: { _ in
                clientLogger.debug("[PREVIEW] processChunk called")
                return TranscriptionProgress(
                    confirmedText: "確定テキスト",
                    pendingText: "未確定テキスト",
                    decodingText: "デコード中...",
                    tokensPerSecond: 15.5
                )
            },
            finalize: {
                clientLogger.debug("[PREVIEW] finalize called")
                return "プレビュー用の文字起こし結果"
            },
            reset: {
                clientLogger.debug("[PREVIEW] reset called")
            }
        )
    }

    static var testValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[TEST] initialize called with \(modelName ?? "nil")")
            },
            processChunk: { _ in
                clientLogger.debug("[TEST] processChunk called")
                return .empty
            },
            finalize: {
                clientLogger.debug("[TEST] finalize called")
                return "テスト用の文字起こし結果"
            },
            reset: {
                clientLogger.debug("[TEST] reset called")
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var streamingTranscription: StreamingTranscriptionClient {
        get { self[StreamingTranscriptionClient.self] }
        set { self[StreamingTranscriptionClient.self] = newValue }
    }
}
