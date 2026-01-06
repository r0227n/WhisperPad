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

    /// WhisperKit が使用可能かどうか
    var isReady: @Sendable () async -> Bool

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

    // MARK: - Configuration

    /// アイドルタイムアウト設定を更新
    /// - Parameters:
    ///   - enabled: タイムアウトを有効にするか
    ///   - minutes: タイムアウト時間（分）
    var configureIdleTimeout: @Sendable (_ enabled: Bool, _ minutes: Int) async -> Void

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
            isReady: {
                true
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
            configureIdleTimeout: { enabled, minutes in
                clientLogger.debug("[PREVIEW] configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
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
            isReady: {
                true
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
            configureIdleTimeout: { enabled, minutes in
                clientLogger.debug("[TEST] configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
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
