//
//  TranscriptionError.swift
//  WhisperPad
//

import Foundation

/// 文字起こし関連のエラー型
enum TranscriptionError: Error, Equatable, Sendable, LocalizedError {
    /// WhisperKit の初期化に失敗
    case initializationFailed(String)
    /// モデルが見つからない
    case modelNotFound(String)
    /// モデルのダウンロードに失敗
    case modelDownloadFailed(String)
    /// モデルの読み込みに失敗
    case modelLoadFailed(String)
    /// 文字起こしに失敗
    case transcriptionFailed(String)
    /// 音声ファイルの読み込みに失敗
    case audioLoadFailed(String)
    /// モデルが読み込まれていない
    case modelNotLoaded
    /// 不明なエラー
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case let .initializationFailed(message):
            String(
                format: String(localized: "error.transcription.initialization_failed"),
                message
            )
        case let .modelNotFound(model):
            String(
                format: String(localized: "error.transcription.model_not_found"),
                model
            )
        case let .modelDownloadFailed(message):
            String(
                format: String(localized: "error.transcription.model_download_failed"),
                message
            )
        case let .modelLoadFailed(message):
            String(
                format: String(localized: "error.transcription.model_load_failed"),
                message
            )
        case let .transcriptionFailed(message):
            String(
                format: String(localized: "error.transcription.transcription_failed"),
                message
            )
        case let .audioLoadFailed(message):
            String(
                format: String(localized: "error.transcription.audio_load_failed"),
                message
            )
        case .modelNotLoaded:
            String(localized: "error.transcription.model_not_loaded")
        case let .unknown(message):
            String(
                format: String(localized: "error.transcription.unknown"),
                message
            )
        }
    }
}
