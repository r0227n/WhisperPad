//
//  AudioRecorderClientLive.swift
//  WhisperPad
//

import AVFoundation
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

                // AudioRecorder.start() が URL を返す
                return try await audioRecorder.start(identifier: identifier)
            },
            endRecording: {
                try await audioRecorder.stop()
            },
            currentTime: {
                await audioRecorder.currentTime
            },
            currentLevel: {
                await audioRecorder.currentLevel
            },
            pauseRecording: {
                await audioRecorder.pause()
            },
            resumeRecording: {
                try await audioRecorder.resume()
            },
            isPaused: {
                await audioRecorder.isPaused
            },
            fetchInputDevices: {
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.microphone, .builtInMicrophone],
                    mediaType: .audio,
                    position: .unspecified
                )
                let defaultDevice = AVCaptureDevice.default(for: .audio)
                return discoverySession.devices.map { device in
                    AudioInputDevice(
                        id: device.uniqueID,
                        name: device.localizedName,
                        isDefault: device.uniqueID == defaultDevice?.uniqueID
                    )
                }
            }
        )
    }
}
