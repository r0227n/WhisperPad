//
//  AudioRecorderClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "AudioRecorderClient")

/// 音声録音クライアント
///
/// マイク権限の要求と音声録音の開始/停止を提供します。
/// 録音形式: 16kHz, モノラル, WAV (PCM) - WhisperKit 推奨設定
struct AudioRecorderClient: Sendable {
    /// マイク権限を要求
    /// - Returns: 権限が許可された場合は true
    var requestPermission: @Sendable () async -> Bool

    /// 録音を開始
    ///
    /// - Parameter identifier: 録音ファイルの一意識別子（UUID文字列など）
    /// - Returns: 録音ファイルの保存先 URL
    /// - Throws: 録音開始に失敗した場合は RecordingError
    ///
    /// URL生成はクライアント内部で行われ、非同期境界での破損を防止します。
    var startRecording: @Sendable (_ identifier: String) async throws -> URL

    /// 録音を終了
    var endRecording: @Sendable () async -> Void

    /// 現在の録音時間を取得
    /// - Returns: 録音中の経過時間（秒）、録音していない場合は nil
    var currentTime: @Sendable () async -> TimeInterval?

    /// 現在の音声レベルを取得
    /// - Returns: 音声レベル（dB）、録音していない場合は nil
    var currentLevel: @Sendable () async -> Float?

    /// 録音を一時停止
    var pauseRecording: @Sendable () async -> Void

    /// 録音を再開
    var resumeRecording: @Sendable () async -> Void

    /// 一時停止中かどうか
    /// - Returns: 一時停止中の場合は true
    var isPaused: @Sendable () async -> Bool
}

// MARK: - TestDependencyKey

extension AudioRecorderClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            requestPermission: { true },
            startRecording: { identifier in
                clientLogger.error("[DEBUG] previewValue.startRecording called!")
                return try Self.generateRecordingURL(identifier: identifier)
            },
            endRecording: {},
            currentTime: { nil },
            currentLevel: { nil },
            pauseRecording: {},
            resumeRecording: {},
            isPaused: { false }
        )
    }

    static var testValue: Self {
        Self(
            requestPermission: { true },
            startRecording: { identifier in
                clientLogger.error("[DEBUG] testValue.startRecording called!")
                return try Self.generateRecordingURL(identifier: identifier)
            },
            endRecording: {},
            currentTime: { nil },
            currentLevel: { nil },
            pauseRecording: {},
            resumeRecording: {},
            isPaused: { false }
        )
    }
}

// MARK: - URL Generation

extension AudioRecorderClient {
    /// 録音URL生成（actor 境界を越える前に呼び出す）
    ///
    /// - Parameter identifier: 録音ファイルの一意識別子（UUID文字列など）
    /// - Returns: 録音ファイルの保存先 URL
    /// - Throws: Caches ディレクトリの取得に失敗した場合
    static func generateRecordingURL(identifier: String) throws -> URL {
        // identifier の検証
        guard !identifier.isEmpty else {
            throw RecordingError.audioFileCreationFailed(
                "Recording identifier cannot be empty"
            )
        }

        // identifier の長さと内容を確認（デバッグ用）
        assert(!identifier.isEmpty, "identifier must not be empty")

        // Caches ディレクトリの取得
        guard let cachePath = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true
        ).first else {
            throw RecordingError.audioFileCreationFailed(
                "Failed to get caches directory path"
            )
        }

        // ディレクトリとファイル名の構築
        let recordingsDirectory = "\(cachePath)/com.whisperpad.recordings"
        let fileName = "whisperpad_\(identifier).wav"
        let fullPath = "\(recordingsDirectory)/\(fileName)"

        return URL(fileURLWithPath: fullPath)
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var audioRecorder: AudioRecorderClient {
        get { self[AudioRecorderClient.self] }
        set { self[AudioRecorderClient.self] = newValue }
    }
}
