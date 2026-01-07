//
//  ModelClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "ModelClient")

/// モデル管理クライアント
///
/// WhisperKit モデルの管理機能を一元化します。
/// モデルの一覧取得、ダウンロード、削除、デフォルトモデルの管理を行います。
struct ModelClient: Sendable {
    // MARK: - Model Listing

    /// 利用可能なモデル一覧を取得
    /// - Returns: 利用可能なモデル名の配列
    var fetchAvailableModels: @Sendable () async throws -> [String]

    /// ローカルにダウンロード済みのモデル一覧を取得
    /// - Returns: ダウンロード済みモデル名の配列
    var fetchDownloadedModels: @Sendable () async throws -> [String]

    /// 推奨モデルを取得
    /// - Returns: デバイスに推奨されるモデル名
    var recommendedModel: @Sendable () async -> String

    /// モデルがダウンロード済みかどうかを確認
    /// - Parameter modelName: モデル名
    /// - Returns: ダウンロード済みの場合は true
    var isModelDownloaded: @Sendable (_ modelName: String) async -> Bool

    /// ダウンロード済みモデル一覧を WhisperModel 型で取得（ソート済み）
    /// - Returns: ダウンロード済みモデルの配列（アルファベット順）
    var fetchDownloadedModelsAsWhisperModels: @Sendable () async throws -> [WhisperModel]

    // MARK: - Model Download/Delete

    /// モデルをダウンロード
    /// - Parameters:
    ///   - modelName: ダウンロードするモデル名
    ///   - progressHandler: 進捗を通知するハンドラ（0.0〜1.0）
    /// - Returns: ダウンロードしたモデルフォルダの URL
    var downloadModel: @Sendable (
        _ modelName: String,
        _ progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> URL

    /// モデルを削除
    /// - Parameter modelName: 削除するモデル名
    var deleteModel: @Sendable (String) async throws -> Void

    // MARK: - Default Model Management

    /// デフォルトモデル名を読み込み（非同期）
    /// - Returns: 保存されているモデル名（未設定の場合は nil）
    var loadDefaultModel: @Sendable () async -> String?

    /// デフォルトモデル名を読み込み（同期）
    /// - Returns: 保存されているモデル名（未設定の場合は nil）
    /// - Note: メニュー初期化時など、同期処理が必要な場合に使用
    var loadDefaultModelSync: @Sendable () -> String?

    /// デフォルトモデル名を保存
    /// - Parameter modelName: 保存するモデル名（nil の場合は削除）
    var saveDefaultModel: @Sendable (String?) async -> Void

    /// デフォルトモデルの有効性を検証
    /// - Parameter downloadedModels: ダウンロード済みモデル名の配列
    /// - Returns: 有効なモデル名、または自動選択されたモデル名。エラーの場合は failure
    var validateDefaultModel: @Sendable ([String]) -> Result<String, ModelClientError>

    // MARK: - Storage Management

    /// ストレージ使用量を取得（バイト）
    var getStorageUsage: @Sendable () async -> Int64

    /// モデル保存先 URL を取得
    var getModelStorageURL: @Sendable () async -> URL

    /// カスタムストレージ場所を設定
    /// - Parameter url: カスタム URL（nil でデフォルトに戻す）
    var setStorageLocation: @Sendable (URL?) async -> Void

    /// ストレージ場所を変更し、WhisperKit を再初期化
    /// - Parameter url: 新しいストレージ URL（nil でデフォルトに戻す）
    var updateStorageLocation: @Sendable (URL?) async -> Void

    /// Security-scoped bookmark を保存
    /// - Parameter url: ブックマーク対象の URL
    var saveStorageBookmark: @Sendable (URL) async throws -> Void

    /// 保存された Security-scoped bookmark を読み込み
    /// - Returns: アクセス可能な URL、または nil
    var loadStorageBookmark: @Sendable () async -> URL?
}

// MARK: - ModelClientError

/// モデル管理関連のエラー型
enum ModelClientError: Error, Equatable, Sendable, LocalizedError {
    /// 利用可能モデル取得に失敗
    case fetchAvailableModelsFailed(String)

    /// ダウンロード済みモデル取得に失敗
    case fetchDownloadedModelsFailed(String)

    /// モデルが見つからない（0件）
    case noModelsFound

    /// デフォルトモデルが無効（ダウンロード済みに存在しない）
    case invalidDefaultModel(String)

    /// モデル選択に失敗
    case selectionFailed(String)

    /// ダウンロードに失敗
    case downloadFailed(String)

    /// 削除に失敗
    case deletionFailed(String)

    var errorDescription: String? {
        switch self {
        case let .fetchAvailableModelsFailed(message):
            String(localized: "error.model.fetch_available_failed") + ": " + message
        case let .fetchDownloadedModelsFailed(message):
            String(localized: "error.model.fetch_downloaded_failed") + ": " + message
        case .noModelsFound:
            String(localized: "error.model.no_models_found")
        case let .invalidDefaultModel(modelName):
            String(localized: "error.model.invalid_default") + ": " + modelName
        case let .selectionFailed(message):
            String(localized: "error.model.selection_failed") + ": " + message
        case let .downloadFailed(message):
            String(localized: "error.model.download_failed") + ": " + message
        case let .deletionFailed(message):
            String(localized: "error.model.deletion_failed") + ": " + message
        }
    }
}

// MARK: - TestDependencyKey

extension ModelClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            fetchAvailableModels: {
                clientLogger.debug("[PREVIEW] fetchAvailableModels called")
                return ["openai_whisper-tiny", "openai_whisper-base", "openai_whisper-small"]
            },
            fetchDownloadedModels: {
                clientLogger.debug("[PREVIEW] fetchDownloadedModels called")
                return ["openai_whisper-tiny", "openai_whisper-base"]
            },
            recommendedModel: {
                "openai_whisper-small"
            },
            isModelDownloaded: { _ in
                false
            },
            fetchDownloadedModelsAsWhisperModels: {
                clientLogger.debug("[PREVIEW] fetchDownloadedModelsAsWhisperModels called")
                return [
                    WhisperModel.from(id: "openai_whisper-base", isDownloaded: true, isRecommended: false),
                    WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false)
                ]
            },
            downloadModel: { modelName, progressHandler in
                clientLogger.debug("[PREVIEW] downloadModel called for \(modelName)")
                for step in 0 ... 10 {
                    try? await Task.sleep(for: .milliseconds(100))
                    progressHandler?(Double(step) / 10.0)
                }
                return URL(fileURLWithPath: "/tmp/models/\(modelName)")
            },
            deleteModel: { modelName in
                clientLogger.debug("[PREVIEW] deleteModel called for \(modelName)")
            },
            loadDefaultModel: {
                clientLogger.debug("[PREVIEW] loadDefaultModel called")
                return "openai_whisper-tiny"
            },
            loadDefaultModelSync: {
                clientLogger.debug("[PREVIEW] loadDefaultModelSync called")
                return "openai_whisper-tiny"
            },
            saveDefaultModel: { modelName in
                clientLogger.debug("[PREVIEW] saveDefaultModel called with \(modelName ?? "nil")")
            },
            validateDefaultModel: { models in
                clientLogger.debug("[PREVIEW] validateDefaultModel called")
                if models.isEmpty {
                    return .failure(.noModelsFound)
                }
                return .success(models.first!)
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
            updateStorageLocation: { url in
                clientLogger.debug("[PREVIEW] updateStorageLocation called: \(url?.path ?? "default")")
            },
            saveStorageBookmark: { url in
                clientLogger.debug("[PREVIEW] saveStorageBookmark called: \(url.path)")
            },
            loadStorageBookmark: {
                clientLogger.debug("[PREVIEW] loadStorageBookmark called")
                return nil
            }
        )
    }

    static var testValue: Self {
        Self(
            fetchAvailableModels: {
                clientLogger.debug("[TEST] fetchAvailableModels called")
                return ["openai_whisper-tiny", "openai_whisper-base"]
            },
            fetchDownloadedModels: {
                clientLogger.debug("[TEST] fetchDownloadedModels called")
                return ["openai_whisper-tiny", "openai_whisper-base"]
            },
            recommendedModel: {
                "openai_whisper-tiny"
            },
            isModelDownloaded: { _ in
                true
            },
            fetchDownloadedModelsAsWhisperModels: {
                clientLogger.debug("[TEST] fetchDownloadedModelsAsWhisperModels called")
                return [
                    WhisperModel.from(id: "openai_whisper-base", isDownloaded: true, isRecommended: false),
                    WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false)
                ]
            },
            downloadModel: { modelName, _ in
                clientLogger.debug("[TEST] downloadModel called for \(modelName)")
                return URL(fileURLWithPath: "/tmp/models/\(modelName)")
            },
            deleteModel: { modelName in
                clientLogger.debug("[TEST] deleteModel called for \(modelName)")
            },
            loadDefaultModel: {
                clientLogger.debug("[TEST] loadDefaultModel called")
                return "openai_whisper-tiny"
            },
            loadDefaultModelSync: {
                clientLogger.debug("[TEST] loadDefaultModelSync called")
                return "openai_whisper-tiny"
            },
            saveDefaultModel: { modelName in
                clientLogger.debug("[TEST] saveDefaultModel called with \(modelName ?? "nil")")
            },
            validateDefaultModel: { models in
                clientLogger.debug("[TEST] validateDefaultModel called")
                if models.isEmpty {
                    return .failure(.noModelsFound)
                }
                return .success(models.first!)
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
            updateStorageLocation: { url in
                clientLogger.debug("[TEST] updateStorageLocation called: \(url?.path ?? "default")")
            },
            saveStorageBookmark: { url in
                clientLogger.debug("[TEST] saveStorageBookmark called: \(url.path)")
            },
            loadStorageBookmark: {
                clientLogger.debug("[TEST] loadStorageBookmark called")
                return nil
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var modelClient: ModelClient {
        get { self[ModelClient.self] }
        set { self[ModelClient.self] = newValue }
    }
}
