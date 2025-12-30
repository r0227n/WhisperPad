//
//  RecordingError.swift
//  WhisperPad
//

import Foundation

/// 録音関連のエラー型
enum RecordingError: Error, Equatable, Sendable, LocalizedError {
    /// マイク権限が拒否された
    case permissionDenied
    /// 録音開始に失敗
    case recordingFailed(String)
    /// 録音URLが設定されていない
    case noRecordingURL
    /// オーディオセッションの設定に失敗
    ///
    /// - Note: macOS では AVAudioSession を使用しないため未使用。
    ///   iOS 対応時に使用予定。
    case audioSessionSetupFailed
    /// AVAudioEngine の開始に失敗
    case audioEngineStartFailed(String)
    /// オーディオファイルの作成に失敗
    case audioFileCreationFailed(String)
    /// オーディオコンバーターの処理に失敗
    case audioConverterFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "マイクへのアクセスが許可されていません。システム環境設定でマイクの権限を許可してください。"
        case let .recordingFailed(message):
            "録音の開始に失敗しました: \(message)"
        case .noRecordingURL:
            "録音ファイルのURLが設定されていません。"
        case .audioSessionSetupFailed:
            "オーディオセッションの設定に失敗しました。"
        case let .audioEngineStartFailed(message):
            "オーディオエンジンの開始に失敗しました: \(message)"
        case let .audioFileCreationFailed(message):
            "オーディオファイルの作成に失敗しました: \(message)"
        case let .audioConverterFailed(message):
            "オーディオ変換に失敗しました: \(message)"
        }
    }
}
