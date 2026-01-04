//
//  TranscriptionClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "TranscriptionClient")

/// 文字起こしクライアント
///
/// WhisperKit を使用したオンデバイス音声認識機能を提供します。
/// 音声ファイルの文字起こしを行います。
/// モデル管理は ModelClient に移動しました。
struct TranscriptionClient: Sendable {
    // MARK: - Initialization

    /// WhisperKit を初期化（モデルを読み込み）
    /// - Parameter modelName: 使用するモデル名（nil の場合は推奨モデルを使用）
    var initialize: @Sendable (_ modelName: String?) async throws -> Void

    /// 現在のモデル状態を取得
    var modelState: @Sendable () async -> TranscriptionModelState

    /// 現在読み込まれているモデル名を取得
    var currentModelName: @Sendable () async -> String?

    // MARK: - Transcription

    /// 音声ファイルを文字起こし
    /// - Parameters:
    ///   - audioURL: 音声ファイルの URL
    ///   - language: 言語コード（nil の場合は自動検出）
    /// - Returns: 文字起こし結果のテキスト
    var transcribe: @Sendable (
        _ audioURL: URL,
        _ language: String?
    ) async throws -> String

    // MARK: - Cleanup

    /// リソースを解放
    var unload: @Sendable () async -> Void
}

// MARK: - TestDependencyKey

extension TranscriptionClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[PREVIEW] initialize called with \(modelName ?? "nil")")
            },
            modelState: {
                .loaded
            },
            currentModelName: {
                "openai_whisper-small"
            },
            transcribe: { audioURL, _ in
                clientLogger.debug("[PREVIEW] transcribe called for \(audioURL.lastPathComponent)")
                return "（プレビュー用のサンプルテキスト）"
            },
            unload: {
                clientLogger.debug("[PREVIEW] unload called")
            }
        )
    }

    static var testValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[TEST] initialize called with \(modelName ?? "nil")")
            },
            modelState: {
                .loaded
            },
            currentModelName: {
                "openai_whisper-tiny"
            },
            transcribe: { audioURL, _ in
                clientLogger.debug("[TEST] transcribe called for \(audioURL.lastPathComponent)")
                return "テスト用の文字起こし結果"
            },
            unload: {
                clientLogger.debug("[TEST] unload called")
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var transcriptionClient: TranscriptionClient {
        get { self[TranscriptionClient.self] }
        set { self[TranscriptionClient.self] = newValue }
    }
}
