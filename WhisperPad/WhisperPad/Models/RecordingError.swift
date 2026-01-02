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
            String(localized: "error.recording.permission_denied")
        case let .recordingFailed(message):
            String(
                format: String(localized: "error.recording.recording_failed"),
                message
            )
        case .noRecordingURL:
            String(localized: "error.recording.no_recording_url")
        case .audioSessionSetupFailed:
            String(localized: "error.recording.audio_session_setup_failed")
        case let .recorderStartFailed(message):
            String(
                format: String(localized: "error.recording.recorder_start_failed"),
                message
            )
        case let .audioFileCreationFailed(message):
            String(
                format: String(localized: "error.recording.audio_file_creation_failed"),
                message
            )
        case let .segmentMergeFailed(message):
            String(
                format: String(localized: "error.recording.segment_merge_failed"),
                message
            )
        }
    }
}
