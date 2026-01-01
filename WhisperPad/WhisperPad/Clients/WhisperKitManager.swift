//
//  WhisperKitManager.swift
//  WhisperPad
//

import Foundation
import OSLog
import WhisperKit

/// WhisperKit インスタンスを一元管理する actor
///
/// アプリ全体で WhisperKit インスタンスを共有し、メモリ効率を向上させます。
/// アプリ起動時に初期化を行い、各機能（通常の文字起こし、ストリーミング）で共有します。
actor WhisperKitManager {
    // MARK: - Singleton

    static let shared = WhisperKitManager()

    // MARK: - Constants

    private static let defaultModelRepo = "argmaxinc/whisperkit-coreml"

    /// デフォルトのモデル保存先ディレクトリ
    private static var defaultModelsDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("WhisperPad/models", isDirectory: true)
    }

    // MARK: - State

    private var whisperKit: WhisperKit?
    private var currentModelName: String?
    private var customStorageURL: URL?
    private(set) var state: WhisperKitState = .unloaded

    private let logger = Logger(subsystem: "com.whisperpad", category: "WhisperKitManager")

    // MARK: - Types

    /// WhisperKit の初期化状態
    enum WhisperKitState: Equatable, Sendable {
        /// 未読み込み
        case unloaded
        /// 初期化中
        case initializing
        /// 準備完了
        case ready
        /// エラー
        case error(String)
    }

    // MARK: - Computed Properties

    /// WhisperKit が使用可能かどうか
    var isReady: Bool {
        state == .ready
    }

    /// 現在読み込まれているモデル名
    var loadedModelName: String? {
        currentModelName
    }

    /// 現在のモデル保存先ディレクトリ
    var modelsDirectory: URL {
        customStorageURL ?? Self.defaultModelsDirectory
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Storage Management

    /// カスタムストレージ場所を設定
    func setStorageLocation(_ url: URL?) {
        customStorageURL = url
        logger.info("Storage location set to: \(url?.path ?? "default")")
    }

    // MARK: - WhisperKit Management

    /// WhisperKit を初期化
    ///
    /// - Parameter modelName: 使用するモデル名。nil の場合は推奨モデルを使用
    /// - Throws: 初期化に失敗した場合
    func initialize(modelName: String?) async throws {
        // 既に初期化済みで同じモデルの場合はスキップ
        if state == .ready, let currentModel = currentModelName {
            if modelName == nil || modelName == currentModel {
                logger.info("WhisperKit already initialized with model: \(currentModel), skipping")
                return
            }
            // 別のモデルが指定された場合は再初期化
            logger.info("Model changed from \(currentModel) to \(modelName ?? "default"), reinitializing")
            await unload()
        }

        // 初期化中の場合はスキップ
        if state == .initializing {
            logger.info("WhisperKit is already initializing, skipping")
            return
        }

        state = .initializing

        let targetModel: String
        if let modelName {
            targetModel = modelName
        } else {
            let modelSupport = WhisperKit.recommendedModels()
            targetModel = modelSupport.default
        }

        logger.info("Initializing WhisperKit with model: \(targetModel)")

        let targetDirectory = modelsDirectory

        do {
            // ダウンロード先ディレクトリを作成
            try FileManager.default.createDirectory(
                at: targetDirectory,
                withIntermediateDirectories: true
            )

            let config = WhisperKitConfig(
                model: targetModel,
                downloadBase: targetDirectory,
                modelRepo: Self.defaultModelRepo,
                verbose: true,
                logLevel: .info,
                prewarm: true,
                load: true,
                download: true
            )

            whisperKit = try await WhisperKit(config)
            currentModelName = targetModel
            state = .ready

            logger.info("WhisperKit initialized successfully with model: \(targetModel)")
        } catch {
            state = .error(error.localizedDescription)
            logger.error("WhisperKit initialization failed: \(error.localizedDescription)")
            throw WhisperKitManagerError.initializationFailed(error.localizedDescription)
        }
    }

    /// WhisperKit インスタンスを取得
    ///
    /// - Returns: 初期化済みの WhisperKit インスタンス、または nil
    func getWhisperKit() -> WhisperKit? {
        whisperKit
    }

    /// リソースを解放
    func unload() async {
        logger.info("Unloading WhisperKit...")
        await whisperKit?.unloadModels()
        whisperKit = nil
        currentModelName = nil
        state = .unloaded
        logger.info("WhisperKit unloaded")
    }
}

// MARK: - Error

/// WhisperKitManager のエラー
enum WhisperKitManagerError: Error, Equatable, Sendable, LocalizedError {
    case initializationFailed(String)
    case notInitialized

    var errorDescription: String? {
        switch self {
        case let .initializationFailed(message):
            "WhisperKit の初期化に失敗しました: \(message)"
        case .notInitialized:
            "WhisperKit が初期化されていません"
        }
    }
}
