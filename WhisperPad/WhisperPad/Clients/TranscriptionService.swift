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

    /// デフォルトのモデル保存先ディレクトリ
    private static var defaultModelsDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("WhisperPad/models", isDirectory: true)
    }

    // MARK: - State

    private var modelState: TranscriptionModelState = .unloaded
    private var customStorageURL: URL?

    /// ロガー
    private let logger = Logger(subsystem: "com.whisperpad", category: "TranscriptionService")

    // MARK: - Computed Properties

    /// 現在のモデル状態
    var state: TranscriptionModelState {
        get async {
            let managerState = await WhisperKitManager.shared.state
            switch managerState {
            case .unloaded:
                return .unloaded
            case .initializing:
                return .loading
            case .ready:
                return .loaded
            case let .error(message):
                return .error(message)
            }
        }
    }

    /// 現在読み込まれているモデル名
    var loadedModelName: String? {
        get async {
            await WhisperKitManager.shared.loadedModelName
        }
    }

    /// 現在のモデル保存先ディレクトリ
    var modelsDirectory: URL {
        customStorageURL ?? Self.defaultModelsDirectory
    }

    /// WhisperKit がモデルを保存する実際のディレクトリ
    /// WhisperKit は downloadBase の中に "models/argmaxinc/whisperkit-coreml/" を作成する
    private var whisperKitModelsDirectory: URL {
        modelsDirectory
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("whisperkit-coreml", isDirectory: true)
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Storage Management

    /// カスタムストレージ場所を設定
    func setStorageLocation(_ url: URL?) {
        customStorageURL = url
        logger.info("Storage location set to: \(url?.path ?? "default")")
    }

    /// ストレージ使用量を取得
    func getStorageUsage() -> Int64 {
        let fileManager = FileManager.default
        let directory = modelsDirectory

        guard fileManager.fileExists(atPath: directory.path) else {
            return 0
        }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        logger.info("Storage usage: \(totalSize) bytes")
        return totalSize
    }

    /// モデルを削除
    func deleteModel(_ modelName: String) throws {
        let modelPath = whisperKitModelsDirectory.appendingPathComponent(modelName)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: modelPath.path) else {
            logger.warning("Model not found for deletion: \(modelName)")
            throw TranscriptionError.modelNotFound(modelName)
        }

        do {
            try fileManager.removeItem(at: modelPath)
            logger.info("Model deleted: \(modelName)")
        } catch {
            logger.error("Failed to delete model: \(error.localizedDescription)")
            throw TranscriptionError.modelDownloadFailed("削除に失敗: \(error.localizedDescription)")
        }
    }

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
    func isModelDownloaded(modelName: String) -> Bool {
        let modelPath = whisperKitModelsDirectory.appendingPathComponent(modelName)
        let exists = FileManager.default.fileExists(atPath: modelPath.path)
        return exists
    }

    /// ローカルにダウンロード済みのモデル一覧を取得
    func fetchDownloadedModels() -> [String] {
        let directory = whisperKitModelsDirectory
        guard FileManager.default.fileExists(atPath: directory.path) else {
            logger.info("Models directory does not exist: \(directory.path)")
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            let models = contents
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
                .map(\.lastPathComponent)
            logger.info("Found \(models.count) downloaded models in \(directory.path)")
            return models
        } catch {
            logger.error("Failed to scan models directory: \(error.localizedDescription)")
            return []
        }
    }

    /// モデルをダウンロード
    func downloadModel(
        modelName: String,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> URL {
        logger.info("Downloading model: \(modelName)")
        modelState = .downloading(progress: 0)

        let targetDirectory = modelsDirectory

        do {
            // ダウンロード先ディレクトリを作成
            try FileManager.default.createDirectory(
                at: targetDirectory,
                withIntermediateDirectories: true
            )

            let modelFolder = try await WhisperKit.download(
                variant: modelName,
                downloadBase: targetDirectory,
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
    ///
    /// WhisperKitManager に委譲して共有インスタンスを初期化します。
    func initialize(modelName: String?) async throws {
        logger.info("Initializing WhisperKit with model: \(modelName ?? "default")")

        do {
            try await WhisperKitManager.shared.initialize(modelName: modelName)
            logger.info("WhisperKit initialized successfully")
        } catch {
            logger.error("WhisperKit initialization failed: \(error.localizedDescription)")
            throw TranscriptionError.initializationFailed(error.localizedDescription)
        }
    }

    // MARK: - Transcription

    /// 音声ファイルを文字起こし
    func transcribe(audioURL: URL, language: String?) async throws -> String {
        guard let whisperKit = await WhisperKitManager.shared.getWhisperKit() else {
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
    ///
    /// WhisperKitManager に委譲して共有インスタンスを解放します。
    func unload() async {
        logger.info("Unloading WhisperKit...")
        await WhisperKitManager.shared.unload()
        logger.info("WhisperKit unloaded")
    }
}
