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

    /// 録音を終了し、全セグメントを結合
    ///
    /// - Returns: 結合されたファイルの情報（部分的な成功の場合も含む）
    /// - Throws: 結合に失敗した場合は RecordingError
    var endRecording: @Sendable () async throws -> StopResult?

    /// 現在の録音時間を取得
    /// - Returns: 録音中の経過時間（秒）、録音していない場合は nil
    var currentTime: @Sendable () async -> TimeInterval?

    /// 現在の音声レベルを取得
    /// - Returns: 音声レベル（dB）、録音していない場合は nil
    var currentLevel: @Sendable () async -> Float?

    /// 現在の音声レベルを取得（モニタリング中または録音中）
    ///
    /// - Returns: 音声レベル（dB）、デフォルトは -60.0（無音）
    var getCurrentAudioLevel: @Sendable () async -> Float

    /// 音声レベルをリアルタイムで監視
    ///
    /// - Returns: 音声レベル（dB）のストリーム
    ///
    /// 30fps（33ms間隔）で音声レベルを更新します。
    /// 設定ウィンドウが開いているときのみ使用し、閉じるときにストリームをキャンセルしてください。
    var observeAudioLevel: @Sendable () -> AsyncStream<Float>

    /// モニタリングを開始（設定画面のマイクテスト用）
    ///
    /// - Throws: モニタリング開始に失敗した場合は RecordingError
    var startMonitoring: @Sendable () async throws -> Void

    /// モニタリングを停止
    var stopMonitoring: @Sendable () async -> Void

    /// 録音を一時停止（マイクを完全に解放）
    var pauseRecording: @Sendable () async -> Void

    /// 録音を再開（新しいセグメントファイルで開始）
    ///
    /// - Throws: セグメントファイルの作成に失敗した場合は RecordingError
    var resumeRecording: @Sendable () async throws -> Void

    /// 一時停止中かどうか
    /// - Returns: 一時停止中の場合は true
    var isPaused: @Sendable () async -> Bool

    /// 利用可能な入力デバイスを取得
    /// - Returns: 入力デバイスの一覧
    var fetchInputDevices: @Sendable () async -> [AudioInputDevice]
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
            endRecording: { nil },
            currentTime: { nil },
            currentLevel: { nil },
            getCurrentAudioLevel: { -60.0 },
            observeAudioLevel: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            startMonitoring: {},
            stopMonitoring: {},
            pauseRecording: {},
            resumeRecording: {},
            isPaused: { false },
            fetchInputDevices: { [.systemDefault] }
        )
    }

    static var testValue: Self {
        Self(
            requestPermission: { true },
            startRecording: { identifier in
                clientLogger.error("[DEBUG] testValue.startRecording called!")
                return try Self.generateRecordingURL(identifier: identifier)
            },
            endRecording: { nil },
            currentTime: { nil },
            currentLevel: { nil },
            getCurrentAudioLevel: { -60.0 },
            observeAudioLevel: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            startMonitoring: {},
            stopMonitoring: {},
            pauseRecording: {},
            resumeRecording: {},
            isPaused: { false },
            fetchInputDevices: { [.systemDefault] }
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
