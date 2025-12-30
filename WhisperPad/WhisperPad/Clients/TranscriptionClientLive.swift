//
//  TranscriptionClientLive.swift
//  WhisperPad
//

import Dependencies
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "TranscriptionClientLive")

// MARK: - DependencyKey

extension TranscriptionClient: DependencyKey {
    /// TranscriptionService のシングルトンインスタンス
    /// liveValue が複数回呼ばれても同じインスタンスを使用
    private static let transcriptionService = TranscriptionService()

    static var liveValue: Self {
        Self(
            fetchAvailableModels: {
                logger.debug("liveValue.fetchAvailableModels called")
                return try await transcriptionService.fetchAvailableModels()
            },
            recommendedModel: {
                logger.debug("liveValue.recommendedModel called")
                return await transcriptionService.recommendedModel()
            },
            isModelDownloaded: { modelName in
                logger.debug("liveValue.isModelDownloaded called for \(modelName)")
                return transcriptionService.isModelDownloaded(modelName: modelName)
            },
            downloadModel: { modelName, progressHandler in
                logger.debug("liveValue.downloadModel called for \(modelName)")
                return try await transcriptionService.downloadModel(
                    modelName: modelName,
                    progressHandler: progressHandler
                )
            },
            initialize: { modelName in
                logger.debug("liveValue.initialize called with \(modelName ?? "nil")")
                try await transcriptionService.initialize(modelName: modelName)
            },
            modelState: {
                logger.debug("liveValue.modelState called")
                return await transcriptionService.state
            },
            currentModelName: {
                logger.debug("liveValue.currentModelName called")
                return await transcriptionService.loadedModelName
            },
            transcribe: { audioURL, language in
                logger.debug("liveValue.transcribe called for \(audioURL.lastPathComponent)")
                return try await transcriptionService.transcribe(
                    audioURL: audioURL,
                    language: language
                )
            },
            unload: {
                logger.debug("liveValue.unload called")
                await transcriptionService.unload()
            }
        )
    }
}
