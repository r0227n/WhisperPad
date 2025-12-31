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
/// モデルの管理（一覧取得、ダウンロード）と音声ファイルの文字起こしを行います。
struct TranscriptionClient: Sendable {
    // MARK: - Model Management

    /// 利用可能なモデル一覧を取得
    /// - Returns: 利用可能なモデル名の配列
    var fetchAvailableModels: @Sendable () async throws -> [String]

    /// 推奨モデルを取得
    /// - Returns: デバイスに推奨されるモデル名
    var recommendedModel: @Sendable () async -> String

    /// モデルがダウンロード済みかどうかを確認
    /// - Parameter modelName: モデル名
    /// - Returns: ダウンロード済みの場合は true
    var isModelDownloaded: @Sendable (_ modelName: String) async -> Bool

    /// モデルをダウンロード
    /// - Parameters:
    ///   - modelName: ダウンロードするモデル名
    ///   - progressHandler: 進捗を通知するハンドラ（0.0〜1.0）
    /// - Returns: ダウンロードしたモデルフォルダの URL
    var downloadModel: @Sendable (
        _ modelName: String,
        _ progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> URL

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

    // MARK: - Storage Management

    /// ストレージ使用量を取得（バイト）
    var getStorageUsage: @Sendable () async -> Int64

    /// モデル保存先 URL を取得
    var getModelStorageURL: @Sendable () async -> URL

    /// カスタムストレージ場所を設定
    /// - Parameter url: カスタム URL（nil でデフォルトに戻す）
    var setStorageLocation: @Sendable (URL?) async -> Void

    /// モデルを削除
    /// - Parameter modelName: 削除するモデル名
    var deleteModel: @Sendable (String) async throws -> Void

    // MARK: - Cleanup

    /// リソースを解放
    var unload: @Sendable () async -> Void
}

// MARK: - TestDependencyKey

extension TranscriptionClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            fetchAvailableModels: {
                clientLogger.debug("[PREVIEW] fetchAvailableModels called")
                return ["openai_whisper-tiny", "openai_whisper-base", "openai_whisper-small"]
            },
            recommendedModel: {
                "openai_whisper-small"
            },
            isModelDownloaded: { _ in
                false
            },
            downloadModel: { modelName, progressHandler in
                clientLogger.debug("[PREVIEW] downloadModel called for \(modelName)")
                // Simulate download progress
                for step in 0 ... 10 {
                    try? await Task.sleep(for: .milliseconds(100))
                    progressHandler?(Double(step) / 10.0)
                }
                return URL(fileURLWithPath: "/tmp/models/\(modelName)")
            },
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
            getStorageUsage: {
                clientLogger.debug("[PREVIEW] getStorageUsage called")
                return 500_000_000 // 500MB
            },
            getModelStorageURL: {
                clientLogger.debug("[PREVIEW] getModelStorageURL called")
                return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                    .first!.appendingPathComponent("WhisperPad/models")
            },
            setStorageLocation: { url in
                clientLogger.debug("[PREVIEW] setStorageLocation called: \(url?.path ?? "default")")
            },
            deleteModel: { modelName in
                clientLogger.debug("[PREVIEW] deleteModel called for \(modelName)")
            },
            unload: {
                clientLogger.debug("[PREVIEW] unload called")
            }
        )
    }

    static var testValue: Self {
        Self(
            fetchAvailableModels: {
                clientLogger.debug("[TEST] fetchAvailableModels called")
                return ["openai_whisper-tiny", "openai_whisper-base"]
            },
            recommendedModel: {
                "openai_whisper-tiny"
            },
            isModelDownloaded: { _ in
                true
            },
            downloadModel: { modelName, _ in
                clientLogger.debug("[TEST] downloadModel called for \(modelName)")
                return URL(fileURLWithPath: "/tmp/models/\(modelName)")
            },
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
            getStorageUsage: {
                clientLogger.debug("[TEST] getStorageUsage called")
                return 250_000_000 // 250MB
            },
            getModelStorageURL: {
                clientLogger.debug("[TEST] getModelStorageURL called")
                return URL(fileURLWithPath: "/tmp/models")
            },
            setStorageLocation: { url in
                clientLogger.debug("[TEST] setStorageLocation called: \(url?.path ?? "default")")
            },
            deleteModel: { modelName in
                clientLogger.debug("[TEST] deleteModel called for \(modelName)")
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
