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
    /// AVAudioRecorder の開始に失敗
    case recorderStartFailed(String)
    /// オーディオファイルの作成に失敗
    case audioFileCreationFailed(String)
    /// 音声セグメントの結合に失敗
    case segmentMergeFailed(String)

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
        case let .recorderStartFailed(message):
            "録音の開始に失敗しました: \(message)"
        case let .audioFileCreationFailed(message):
            "オーディオファイルの作成に失敗しました: \(message)"
        case let .segmentMergeFailed(message):
            "音声セグメントの結合に失敗しました: \(message)"
        }
    }
}
