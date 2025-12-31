//
//  StreamingAudioClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "StreamingAudioClient")

/// ストリーミング音声クライアント
///
/// WhisperKit の AudioProcessor を使用してリアルタイム音声ストリームを提供します。
struct StreamingAudioClient: Sendable {
    /// マイク入力のリアルタイムストリーミングを開始
    var startRecording: @Sendable () async throws -> AsyncThrowingStream<[Float], Error>

    /// 録音を停止
    var stopRecording: @Sendable () async -> Void

    /// 録音中かどうか
    var isRecording: @Sendable () async -> Bool
}

// MARK: - DependencyKey

extension StreamingAudioClient: DependencyKey {
    private actor ServiceHolder {
        static let shared = ServiceHolder()
        private var _service: StreamingAudioService?

        func getService() -> StreamingAudioService {
            if _service == nil {
                _service = StreamingAudioService()
            }
            return _service!
        }
    }

    static var liveValue: Self {
        Self(
            startRecording: {
                let service = await ServiceHolder.shared.getService()
                return try await service.startLiveRecording()
            },
            stopRecording: {
                let service = await ServiceHolder.shared.getService()
                await service.stopRecording()
            },
            isRecording: {
                let service = await ServiceHolder.shared.getService()
                return await service.isRecording
            }
        )
    }
}

// MARK: - TestDependencyKey

extension StreamingAudioClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            startRecording: {
                clientLogger.debug("[PREVIEW] startRecording called")
                return AsyncThrowingStream { continuation in
                    Task {
                        // シミュレートされた音声データを生成
                        for _ in 0 ..< 10 {
                            try? await Task.sleep(for: .milliseconds(100))
                            let samples = (0 ..< 1600).map { _ in Float.random(in: -0.1 ... 0.1) }
                            continuation.yield(samples)
                        }
                        continuation.finish()
                    }
                }
            },
            stopRecording: {
                clientLogger.debug("[PREVIEW] stopRecording called")
            },
            isRecording: {
                false
            }
        )
    }

    static var testValue: Self {
        Self(
            startRecording: {
                clientLogger.debug("[TEST] startRecording called")
                return AsyncThrowingStream { continuation in
                    let samples = (0 ..< 1600).map { _ in Float.random(in: -0.1 ... 0.1) }
                    continuation.yield(samples)
                    continuation.finish()
                }
            },
            stopRecording: {
                clientLogger.debug("[TEST] stopRecording called")
            },
            isRecording: {
                false
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var streamingAudio: StreamingAudioClient {
        get { self[StreamingAudioClient.self] }
        set { self[StreamingAudioClient.self] = newValue }
    }
}
