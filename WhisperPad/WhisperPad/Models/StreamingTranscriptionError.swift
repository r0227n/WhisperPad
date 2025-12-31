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
            "ストリーミング文字起こしの初期化に失敗しました: \(message)"
        case let .processingFailed(message):
            "音声処理に失敗しました: \(message)"
        case .bufferOverflow:
            "音声バッファがオーバーフローしました。処理が追いついていません。"
        case .microphonePermissionDenied:
            "マイクへのアクセスが許可されていません。システム環境設定でマイクの権限を許可してください。"
        }
    }
}
