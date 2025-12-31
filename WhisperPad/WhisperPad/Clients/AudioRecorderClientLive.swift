//
//  AudioRecorderClientLive.swift
//  WhisperPad
//

import Dependencies
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "AudioRecorderClientLive")

// MARK: - DependencyKey

extension AudioRecorderClient: DependencyKey {
    /// AudioRecorderのシングルトンインスタンス
    /// liveValueが複数回呼ばれても同じインスタンスを使用し、use-after-freeを防止
    private static let audioRecorder = AudioRecorder()

    static var liveValue: Self {
        Self(
            requestPermission: {
                await AudioRecorder.requestPermission()
            },
            startRecording: { identifier in
                // identifier の検証（early return で安全性を確保）
                guard !identifier.isEmpty else {
                    throw RecordingError.audioFileCreationFailed(
                        "Recording identifier cannot be empty"
                    )
                }

                // URL 生成を actor 境界を越える前に行う
                let url = try Self.generateRecordingURL(identifier: identifier)
                try await audioRecorder.start(url: url)
                return url
            },
            endRecording: {
                await audioRecorder.stop()
            },
            currentTime: {
                await audioRecorder.currentTime
            },
            currentLevel: {
                await audioRecorder.currentLevel
            }
        )
    }
}
