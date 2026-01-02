//
//  StreamingTranscriptionError.swift
//  WhisperPad
//

import Foundation

/// ストリーミング文字起こし関連のエラー型
enum StreamingTranscriptionError: Error, Equatable, Sendable, LocalizedError {
    /// 初期化に失敗
    case initializationFailed(String)

    /// 処理に失敗
    case processingFailed(String)

    /// バッファオーバーフロー
    case bufferOverflow

    /// マイク権限が拒否された
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case let .initializationFailed(message):
            String(
                format: String(localized: "error.streaming.initialization_failed"),
                message
            )
        case let .processingFailed(message):
            String(
                format: String(localized: "error.streaming.processing_failed"),
                message
            )
        case .bufferOverflow:
            String(localized: "error.streaming.buffer_overflow")
        case .microphonePermissionDenied:
            String(localized: "error.streaming.microphone_permission_denied")
        }
    }
}
