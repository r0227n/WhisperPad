//
//  ModelClientLive.swift
//  WhisperPad
//

import Dependencies
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "ModelClientLive")

// MARK: - DependencyKey

extension ModelClient: DependencyKey {
    static var liveValue: Self {
        Self(
            fetchAvailableModels: {
                logger.debug("liveValue.fetchAvailableModels called")
                return try await WhisperKitManager.shared.fetchAvailableModels()
            },
            fetchDownloadedModels: {
                logger.debug("liveValue.fetchDownloadedModels called")
                return await WhisperKitManager.shared.fetchDownloadedModels()
            },
            recommendedModel: {
                logger.debug("liveValue.recommendedModel called")
                return await WhisperKitManager.shared.recommendedModel()
            },
            isModelDownloaded: { modelName in
                logger.debug("liveValue.isModelDownloaded called for \(modelName)")
                return await WhisperKitManager.shared.isModelDownloaded(modelName: modelName)
            },
            fetchDownloadedModelsAsWhisperModels: {
                logger.debug("liveValue.fetchDownloadedModelsAsWhisperModels called")
                let modelNames = await WhisperKitManager.shared.fetchDownloadedModels()
                let recommendedModel = await WhisperKitManager.shared.recommendedModel()
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
                return try await WhisperKitManager.shared.downloadModel(
                    modelName: modelName,
                    progressHandler: progressHandler
                )
            },
            deleteModel: { modelName in
                logger.debug("liveValue.deleteModel called for \(modelName)")
                try await WhisperKitManager.shared.deleteModel(modelName)
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
                return await WhisperKitManager.shared.getStorageUsage()
            },
            getModelStorageURL: {
                logger.debug("liveValue.getModelStorageURL called")
                return await WhisperKitManager.shared.modelsDirectory
            },
            setStorageLocation: { url in
                logger.debug("liveValue.setStorageLocation called: \(url?.path ?? "default")")
                await WhisperKitManager.shared.setStorageLocation(url)
            },
            updateStorageLocation: { url in
                logger.debug("liveValue.updateStorageLocation called: \(url?.path ?? "default")")
                await WhisperKitManager.shared.updateStorageLocation(url)
            },
            saveStorageBookmark: { url in
                logger.debug("liveValue.saveStorageBookmark called: \(url.path)")
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: AppSettings.Keys.storageBookmark)
                logger.info("Storage bookmark saved for: \(url.path)")
            },
            loadStorageBookmark: {
                logger.debug("liveValue.loadStorageBookmark called")
                guard let bookmarkData = UserDefaults.standard.data(
                    forKey: AppSettings.Keys.storageBookmark
                ) else {
                    logger.debug("No storage bookmark found")
                    return nil
                }

                do {
                    var isStale = false
                    let url = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: .withSecurityScope,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )

                    if isStale {
                        logger.warning("Storage bookmark is stale, attempting to refresh")
                        // Refresh stale bookmark
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            let newBookmarkData = try url.bookmarkData(
                                options: .withSecurityScope,
                                includingResourceValuesForKeys: nil,
                                relativeTo: nil
                            )
                            UserDefaults.standard.set(
                                newBookmarkData,
                                forKey: AppSettings.Keys.storageBookmark
                            )
                            logger.info("Refreshed stale bookmark for: \(url.path)")
                        }
                    }

                    // Start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        logger.error("Failed to access security-scoped resource: \(url.path)")
                        return nil
                    }

                    logger.info("Storage bookmark loaded and access started: \(url.path)")
                    return url
                } catch {
                    logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
                    return nil
                }
            }
        )
    }
}
