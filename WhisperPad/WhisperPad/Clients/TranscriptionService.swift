//
//  TranscriptionService.swift
//  WhisperPad
//

import Foundation
import OSLog
import WhisperKit

/// WhisperKit を使用した文字起こしサービス actor
///
/// WhisperKit のライフサイクル（初期化、モデル管理、文字起こし）を管理します。
/// actor として実装することで、スレッドセーフな操作を保証します。
actor TranscriptionService {
    // MARK: - Constants

    /// デフォルトのモデルリポジトリ
    static let defaultModelRepo = "argmaxinc/whisperkit-coreml"

    /// モデル保存先ディレクトリ
    private static var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("WhisperPad/models", isDirectory: true)
    }

    // MARK: - State

    private var whisperKit: WhisperKit?
    private var currentModelName: String?
    private var modelState: TranscriptionModelState = .unloaded

    /// ロガー
    private let logger = Logger(subsystem: "com.whisperpad", category: "TranscriptionService")

    // MARK: - Computed Properties

    /// 現在のモデル状態
    var state: TranscriptionModelState {
        modelState
    }

    /// 現在読み込まれているモデル名
    var loadedModelName: String? {
        currentModelName
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Model Management

    /// 利用可能なモデル一覧を取得
    func fetchAvailableModels() async throws -> [String] {
        logger.info("Fetching available models...")

        do {
            let models = try await WhisperKit.fetchAvailableModels(
                from: Self.defaultModelRepo
            )
            logger.info("Found \(models.count) available models")
            return models
        } catch {
            logger.error("Failed to fetch models: \(error.localizedDescription)")
            throw TranscriptionError.modelNotFound("モデル一覧の取得に失敗: \(error.localizedDescription)")
        }
    }

    /// 推奨モデルを取得
    func recommendedModel() async -> String {
        let modelSupport = await WhisperKit.recommendedModels()
        logger.info("Recommended model: \(modelSupport.default)")
        return modelSupport.default
    }

    /// モデルがダウンロード済みかどうかを確認
    nonisolated func isModelDownloaded(modelName: String) -> Bool {
        let modelPath = Self.modelsDirectory.appendingPathComponent(modelName)
        let exists = FileManager.default.fileExists(atPath: modelPath.path)
        return exists
    }

    /// モデルをダウンロード
    func downloadModel(
        modelName: String,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> URL {
        logger.info("Downloading model: \(modelName)")
        modelState = .downloading(progress: 0)

        do {
            // ダウンロード先ディレクトリを作成
            try FileManager.default.createDirectory(
                at: Self.modelsDirectory,
                withIntermediateDirectories: true
            )

            let modelFolder = try await WhisperKit.download(
                variant: modelName,
                downloadBase: Self.modelsDirectory,
                from: Self.defaultModelRepo,
                progressCallback: { progress in
                    let progressValue = progress.fractionCompleted
                    Task { @MainActor in
                        progressHandler?(progressValue)
                    }
                    // Update internal state
                    Task {
                        await self.updateDownloadProgress(progressValue)
                    }
                }
            )

            modelState = .unloaded
            logger.info("Model downloaded to: \(modelFolder.path)")
            return modelFolder
        } catch {
            modelState = .error(error.localizedDescription)
            logger.error("Model download failed: \(error.localizedDescription)")
            throw TranscriptionError.modelDownloadFailed(error.localizedDescription)
        }
    }

    /// ダウンロード進捗を更新
    private func updateDownloadProgress(_ progress: Double) {
        modelState = .downloading(progress: progress)
    }

    // MARK: - Initialization and Loading

    /// WhisperKit を初期化（モデルを読み込み）
    func initialize(modelName: String?) async throws {
        let targetModel: String = if let modelName {
            modelName
        } else {
            await recommendedModel()
        }
        logger.info("Initializing WhisperKit with model: \(targetModel)")

        modelState = .loading

        do {
            let config = WhisperKitConfig(
                model: targetModel,
                downloadBase: Self.modelsDirectory,
                modelRepo: Self.defaultModelRepo,
                verbose: true,
                logLevel: .info,
                prewarm: true,
                load: true,
                download: true
            )

            whisperKit = try await WhisperKit(config)
            currentModelName = targetModel
            modelState = .loaded

            logger.info("WhisperKit initialized successfully with model: \(targetModel)")
        } catch {
            modelState = .error(error.localizedDescription)
            logger.error("WhisperKit initialization failed: \(error.localizedDescription)")
            throw TranscriptionError.initializationFailed(error.localizedDescription)
        }
    }

    // MARK: - Transcription

    /// 音声ファイルを文字起こし
    func transcribe(audioURL: URL, language: String?) async throws -> String {
        guard let whisperKit else {
            logger.error("Transcription attempted without initialized WhisperKit")
            throw TranscriptionError.modelNotLoaded
        }

        logger.info("Starting transcription for: \(audioURL.lastPathComponent)")

        do {
            // DecodingOptions を設定
            var options = DecodingOptions()
            options.language = language
            options.task = .transcribe
            options.verbose = false

            // 文字起こしを実行
            let results = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: options
            )

            // 結果を結合
            let transcribedText = results.map(\.text).joined(separator: " ")
            let trimmedText = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)

            logger.info("Transcription completed: \(trimmedText.prefix(50))...")
            return trimmedText
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
    }

    // MARK: - Cleanup

    /// リソースを解放
    func unload() async {
        logger.info("Unloading WhisperKit...")
        await whisperKit?.unloadModels()
        whisperKit = nil
        currentModelName = nil
        modelState = .unloaded
        logger.info("WhisperKit unloaded")
    }
}
