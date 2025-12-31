//
//  AudioRecorder.swift
//  WhisperPad
//

import AppKit
@preconcurrency import AVFAudio
import AVFoundation
import OSLog

/// AVAudioRecorder を使用した音声録音 actor
///
/// TCA公式パターンに準拠し、シングルトンではなくインスタンスベースで動作します。
/// URL生成は AudioRecorderClient で行い、actor 境界を越える問題を回避します。
actor AudioRecorder {
    // MARK: - Constants

    /// WhisperKit 推奨設定
    static let targetSampleRate: Double = 16000.0
    static let targetChannels: Int = 1
    static let targetBitDepth: Int = 16

    /// 録音設定 (16kHz, mono, 16-bit PCM WAV)
    private static let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: targetSampleRate,
        AVNumberOfChannelsKey: targetChannels,
        AVLinearPCMBitDepthKey: targetBitDepth,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false
    ]

    // MARK: - State

    private var recorder: AVAudioRecorder?
    private var startTime: Date?
    private var isPausedState: Bool = false

    /// ロガー
    private let logger = Logger(subsystem: "com.whisperpad", category: "AudioRecorder")

    // MARK: - Computed Properties

    /// 録音中かどうか
    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    /// 一時停止中かどうか
    var isPaused: Bool {
        isPausedState
    }

    /// 現在の録音時間
    var currentTime: TimeInterval? {
        guard let recorder, recorder.isRecording else { return nil }
        return recorder.currentTime
    }

    /// 現在の音声レベル (dB)
    var currentLevel: Float? {
        guard let recorder, recorder.isRecording else { return nil }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Static Methods

    /// マイク権限を要求
    static func requestPermission() async -> Bool {
        // メニューバーアプリでダイアログを表示するためにアプリをアクティブ化
        await MainActor.run {
            NSApp.activate(ignoringOtherApps: true)
        }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording Methods

    /// 録音を開始
    ///
    /// - Parameter url: 録音ファイルの保存先 URL（AudioRecorderClient で生成済み）
    /// - Throws: 録音開始に失敗した場合は RecordingError
    func start(url: URL) async throws {
        // 既存の録音を停止
        stop()

        // ディレクトリ準備
        try prepareDirectory(for: url)

        // 録音開始
        try startRecordingInternal(url: url)
    }

    /// 録音を停止
    func stop() {
        recorder?.stop()
        recorder = nil
        startTime = nil
        isPausedState = false
    }

    /// 録音を一時停止
    func pause() {
        guard let recorder, recorder.isRecording else { return }
        recorder.pause()
        isPausedState = true
        logger.info("Recording paused")
    }

    /// 録音を再開
    func resume() {
        guard let recorder, isPausedState else { return }
        recorder.record()
        isPausedState = false
        logger.info("Recording resumed")
    }

    // MARK: - Private Methods

    /// 保存先ディレクトリを準備
    private func prepareDirectory(for url: URL) throws {
        // URLバリデーション
        guard url.pathComponents.count > 1 else {
            throw RecordingError.audioFileCreationFailed(
                "Invalid URL: \(url.absoluteString)"
            )
        }

        let directory = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create directory: \(error.localizedDescription)")
            throw RecordingError.audioFileCreationFailed(
                "Failed to create directory at \(directory.path): \(error.localizedDescription)"
            )
        }
    }

    /// 内部録音開始処理
    private func startRecordingInternal(url: URL) throws {
        do {
            recorder = try AVAudioRecorder(url: url, settings: Self.recordingSettings)
        } catch {
            logger.error("Failed to create AVAudioRecorder: \(error.localizedDescription)")
            throw RecordingError.audioFileCreationFailed(
                "Failed to create recorder at \(url.path): \(error.localizedDescription)"
            )
        }

        guard let recorder else {
            throw RecordingError.recorderStartFailed("Recorder instance is nil")
        }

        // メータリングを有効化
        recorder.isMeteringEnabled = true

        // 録音開始
        guard recorder.record() else {
            self.recorder = nil
            throw RecordingError.recorderStartFailed("Failed to start recording at \(url.path)")
        }

        startTime = Date()
        logger.info("Recording started: \(url.lastPathComponent)")
    }
}
