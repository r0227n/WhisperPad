//
//  ModelClientLive.swift
//  WhisperPad
//

import Dependencies
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "ModelClientLive")

// MARK: - DependencyKey

extension ModelClient: DependencyKey {
    /// TranscriptionService のシングルトンインスタンス
    /// liveValue が複数回呼ばれても同じインスタンスを使用
    private static let transcriptionService = TranscriptionService()

    static var liveValue: Self {
        Self(
            fetchAvailableModels: {
                logger.debug("liveValue.fetchAvailableModels called")
                return try await transcriptionService.fetchAvailableModels()
            },
            fetchDownloadedModels: {
                logger.debug("liveValue.fetchDownloadedModels called")
                return await transcriptionService.fetchDownloadedModels()
            },
            recommendedModel: {
                logger.debug("liveValue.recommendedModel called")
                return await transcriptionService.recommendedModel()
            },
            isModelDownloaded: { modelName in
                logger.debug("liveValue.isModelDownloaded called for \(modelName)")
                return await transcriptionService.isModelDownloaded(modelName: modelName)
            },
            fetchDownloadedModelsAsWhisperModels: {
                logger.debug("liveValue.fetchDownloadedModelsAsWhisperModels called")
                let modelNames = await transcriptionService.fetchDownloadedModels()
                let recommendedModel = await transcriptionService.recommendedModel()
                var models: [WhisperModel] = modelNames.map { name in
                    WhisperModel.from(
                        id: name,
                        isDownloaded: true,
                        isRecommended: name == recommendedModel
                    )
                }
                models.sort { $0.id < $1.id }
                return models
            },
            downloadModel: { modelName, progressHandler in
                logger.debug("liveValue.downloadModel called for \(modelName)")
                return try await transcriptionService.downloadModel(
                    modelName: modelName,
                    progressHandler: progressHandler
                )
            },
            deleteModel: { modelName in
                logger.debug("liveValue.deleteModel called for \(modelName)")
                try await transcriptionService.deleteModel(modelName)
            },
            loadDefaultModel: {
                logger.debug("liveValue.loadDefaultModel called")
                return UserDefaults.standard.string(forKey: AppSettings.Keys.defaultModel)
            },
            loadDefaultModelSync: {
                logger.debug("liveValue.loadDefaultModelSync called")
                return UserDefaults.standard.string(forKey: AppSettings.Keys.defaultModel)
            },
            saveDefaultModel: { modelName in
                logger.debug("liveValue.saveDefaultModel called: \(modelName ?? "nil")")
                if let modelName {
                    UserDefaults.standard.set(modelName, forKey: AppSettings.Keys.defaultModel)
                } else {
                    UserDefaults.standard.removeObject(forKey: AppSettings.Keys.defaultModel)
                }
            },
            validateDefaultModel: { downloadedModels in
                logger.debug("liveValue.validateDefaultModel called")

                guard !downloadedModels.isEmpty else {
                    return .failure(.noModelsFound)
                }

                let currentDefault = UserDefaults.standard.string(forKey: AppSettings.Keys.defaultModel)

                // デフォルトモデルが有効な場合
                if let defaultModel = currentDefault, downloadedModels.contains(defaultModel) {
                    return .success(defaultModel)
                }

                // デフォルトモデルが無効な場合、最初のモデルを自動選択
                let newDefault = downloadedModels.first!
                UserDefaults.standard.set(newDefault, forKey: AppSettings.Keys.defaultModel)
                logger.info("Auto-selected model: \(newDefault)")
                return .success(newDefault)
            },
            getStorageUsage: {
                logger.debug("liveValue.getStorageUsage called")
                return await transcriptionService.getStorageUsage()
            },
            getModelStorageURL: {
                logger.debug("liveValue.getModelStorageURL called")
                return await transcriptionService.modelsDirectory
            },
            setStorageLocation: { url in
                logger.debug("liveValue.setStorageLocation called: \(url?.path ?? "default")")
                await transcriptionService.setStorageLocation(url)
            }
        )
    }
}
