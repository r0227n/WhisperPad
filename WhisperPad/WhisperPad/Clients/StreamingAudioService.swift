//
//  StreamingAudioService.swift
//  WhisperPad
//

import Foundation
import OSLog
import WhisperKit

/// リアルタイム音声ストリーミングサービス
///
/// WhisperKit の AudioProcessor を使用してマイク入力をストリーミングで取得します。
/// AudioProcessor と CoreAudio API はメインスレッドで操作する必要があるため、
/// @MainActor で実行します。
@MainActor
final class StreamingAudioService {
    // MARK: - Constants

    private let logger = Logger(
        subsystem: "com.whisperpad",
        category: "StreamingAudioService"
    )

    // MARK: - State

    private var audioProcessor: AudioProcessor?
    private var streamContinuation: AsyncThrowingStream<[Float], Error>.Continuation?
    private var isCurrentlyRecording = false

    // MARK: - Computed Properties

    var isRecording: Bool {
        isCurrentlyRecording
    }

    // MARK: - Recording

    /// マイク入力のリアルタイムストリーミングを開始
    func startLiveRecording() throws -> AsyncThrowingStream<[Float], Error> {
        guard !isCurrentlyRecording else {
            logger.warning("Recording already in progress")
            throw StreamingTranscriptionError.initializationFailed("Already recording")
        }

        logger.info("Starting live recording...")

        let processor = AudioProcessor()
        let (stream, continuation) = processor.startStreamingRecordingLive(inputDeviceID: nil)

        self.audioProcessor = processor
        self.streamContinuation = continuation
        self.isCurrentlyRecording = true

        logger.info("Live recording started successfully")
        return stream
    }

    /// 録音を停止
    func stopRecording() {
        guard isCurrentlyRecording else {
            logger.warning("No recording in progress")
            return
        }

        logger.info("Stopping recording...")

        streamContinuation?.finish()
        audioProcessor?.stopRecording()

        streamContinuation = nil
        audioProcessor = nil
        isCurrentlyRecording = false

        logger.info("Recording stopped")
    }
}
