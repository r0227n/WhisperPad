//
//  TranscriptionClientLive.swift
//  WhisperPad
//

import Dependencies
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "TranscriptionClientLive")

// MARK: - DependencyKey

extension TranscriptionClient: DependencyKey {
    static var liveValue: Self {
        Self(
            initialize: { modelName in
                logger.debug("liveValue.initialize called with \(modelName ?? "nil")")
                try await WhisperKitManager.shared.initialize(modelName: modelName)
            },
            isReady: {
                logger.debug("liveValue.isReady called")
                return await WhisperKitManager.shared.isReady
            },
            modelState: {
                logger.debug("liveValue.modelState called")
                return await WhisperKitManager.shared.transcriptionModelState
            },
            currentModelName: {
                logger.debug("liveValue.currentModelName called")
                return await WhisperKitManager.shared.loadedModelName
            },
            transcribe: { audioURL, language in
                logger.debug("liveValue.transcribe called for \(audioURL.lastPathComponent)")
                return try await WhisperKitManager.shared.transcribe(
                    audioURL: audioURL,
                    language: language
                )
            },
            configureIdleTimeout: { enabled, minutes in
                logger.debug("liveValue.configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
                await WhisperKitManager.shared.configureIdleTimeout(enabled: enabled, minutes: minutes)
            },
            unload: {
                logger.debug("liveValue.unload called")
                await WhisperKitManager.shared.unload()
            }
        )
    }
}
