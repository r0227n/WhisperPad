//
//  AudioRecorder.swift
//  WhisperPad
//

import AppKit
@preconcurrency import AVFAudio
import AVFoundation
import CoreMedia
import OSLog

/// 録音停止の結果
struct StopResult: Sendable, Equatable {
    let url: URL
    let isPartial: Bool
    let usedSegments: Int
    let totalSegments: Int
}

/// AVAudioRecorder を使用した音声録音 actor
///
/// TCA公式パターンに準拠し、シングルトンではなくインスタンスベースで動作します。
/// URL生成は AudioRecorderClient で行い、actor 境界を越える問題を回避します。
///
/// 一時停止時はマイク入力を完全に解放するため、複数セグメント方式で録音を管理します。
/// 録音終了時に全セグメントを1つのファイルに結合します。
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

    /// セグメント管理（複数ファイル方式で一時停止時にマイクを解放）
    private var segmentURLs: [URL] = []
    private var currentSegmentIndex: Int = 0
    private var baseIdentifier: String = ""
    private var accumulatedDuration: TimeInterval = 0

    /// ロガー
    private let logger = Logger(subsystem: "com.whisperpad", category: "AudioRecorder")

    // MARK: - Computed Properties

    /// 録音中かどうか
    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    /// 一時停止中かどうか（録音セッション中だが recorder が nil）
    var isPaused: Bool {
        !baseIdentifier.isEmpty && recorder == nil
    }

    /// 現在の録音時間（累積 + 現在のセグメント）
    var currentTime: TimeInterval? {
        guard !baseIdentifier.isEmpty else { return nil }
        return accumulatedDuration + (recorder?.currentTime ?? 0)
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
    /// - Parameter identifier: 録音セッションの識別子
    /// - Returns: 最終的な出力ファイルのURL（結合後のファイル）
    /// - Throws: 録音開始に失敗した場合は RecordingError
    func start(identifier: String) async throws -> URL {
        // 既存のセッションをクリーンアップ
        cleanup()

        // セッション初期化
        baseIdentifier = identifier
        currentSegmentIndex = 0
        segmentURLs = []
        accumulatedDuration = 0

        // 最初のセグメントで録音開始
        let url = try generateSegmentURL(segmentIndex: 0)
        try prepareDirectory(for: url)
        try startRecordingInternal(url: url)

        // セグメントURLを記録
        segmentURLs.append(url)

        // 最終的な出力URLを返す
        return try AudioRecorderClient.generateRecordingURL(identifier: identifier)
    }

    /// 録音を停止し、全セグメントを結合
    ///
    /// - Returns: 結合されたファイルの情報（部分的な成功の場合も含む）
    func stop() async throws -> StopResult? {
        // 現在録音中なら停止
        if let recorder, recorder.isRecording {
            accumulatedDuration += recorder.currentTime
            recorder.stop()
        }
        self.recorder = nil

        // セグメントがない場合
        guard !segmentURLs.isEmpty else {
            logger.warning("No segments to process")
            cleanup()
            return nil
        }

        let totalCount = segmentURLs.count

        // セグメントが1つだけの場合は結合不要
        if segmentURLs.count == 1 {
            let finalURL = try AudioRecorderClient.generateRecordingURL(identifier: baseIdentifier)
            // 既存ファイルがあれば削除
            if FileManager.default.fileExists(atPath: finalURL.path) {
                try FileManager.default.removeItem(at: finalURL)
            }
            try FileManager.default.moveItem(at: segmentURLs[0], to: finalURL)
            cleanup()
            return StopResult(url: finalURL, isPartial: false, usedSegments: 1, totalSegments: 1)
        }

        // 複数セグメントを結合
        do {
            let finalURL = try await mergeSegments()
            cleanupSegmentFiles()
            cleanup()
            return StopResult(url: finalURL, isPartial: false, usedSegments: totalCount, totalSegments: totalCount)
        } catch {
            // 結合失敗時は最初のセグメントのみを使用
            logger.error("Segment merge failed: \(error.localizedDescription). Using first segment only.")
            let finalURL = try AudioRecorderClient.generateRecordingURL(identifier: baseIdentifier)
            // 既存ファイルがあれば削除
            if FileManager.default.fileExists(atPath: finalURL.path) {
                try FileManager.default.removeItem(at: finalURL)
            }
            try FileManager.default.moveItem(at: segmentURLs[0], to: finalURL)

            // 残りのセグメントを削除
            for index in 1 ..< segmentURLs.count {
                try? FileManager.default.removeItem(at: segmentURLs[index])
            }
            cleanup()
            return StopResult(url: finalURL, isPartial: true, usedSegments: 1, totalSegments: totalCount)
        }
    }

    /// 録音を一時停止（マイクを完全に解放）
    func pause() async {
        guard let recorder, recorder.isRecording else { return }

        // 現在のセグメントの録音時間を累積
        accumulatedDuration += recorder.currentTime

        // 録音を完全に停止（マイク解放）
        recorder.stop()
        self.recorder = nil

        logger.info("Recording paused - segment \(self.currentSegmentIndex) saved, mic released")
    }

    /// 録音を再開（新しいセグメントファイルで開始）
    func resume() async throws {
        guard recorder == nil, !baseIdentifier.isEmpty else { return }

        // 新しいセグメントインデックス
        currentSegmentIndex += 1

        // 新しいセグメントファイルで録音開始
        let url = try generateSegmentURL(segmentIndex: currentSegmentIndex)
        try prepareDirectory(for: url)
        try startRecordingInternal(url: url)

        // セグメントURLを記録
        segmentURLs.append(url)

        logger.info("Recording resumed - new segment \(self.currentSegmentIndex)")
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

    // MARK: - Segment Management

    /// セグメント用のURLを生成
    private func generateSegmentURL(segmentIndex: Int) throws -> URL {
        guard let cachePath = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory, .userDomainMask, true
        ).first else {
            throw RecordingError.audioFileCreationFailed("Failed to get caches directory")
        }

        let recordingsDirectory = "\(cachePath)/com.whisperpad.recordings"
        let fileName = "whisperpad_\(baseIdentifier)_segment\(segmentIndex).wav"
        return URL(fileURLWithPath: "\(recordingsDirectory)/\(fileName)")
    }

    /// 全セグメントを1つのファイルに結合
    private func mergeSegments() async throws -> URL {
        let composition = AVMutableComposition()

        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw RecordingError.segmentMergeFailed("Failed to create composition track")
        }

        var insertTime = CMTime.zero

        for segmentURL in segmentURLs {
            let asset = AVURLAsset(url: segmentURL)

            // 非同期でトラックを読み込み
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            guard let assetTrack = tracks.first else {
                logger.warning("No audio track in segment: \(segmentURL.lastPathComponent)")
                continue
            }

            let duration = try await asset.load(.duration)

            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: assetTrack,
                at: insertTime
            )

            insertTime = CMTimeAdd(insertTime, duration)
        }

        // 結合ファイルをエクスポート
        let outputURL = try AudioRecorderClient.generateRecordingURL(identifier: baseIdentifier)
        try await exportComposition(composition, to: outputURL)

        logger.info("Merged \(self.segmentURLs.count) segments into \(outputURL.lastPathComponent)")
        return outputURL
    }

    /// AVMutableComposition を WAV ファイルとしてエクスポート
    private func exportComposition(_ composition: AVMutableComposition, to url: URL) async throws {
        // 既存ファイルがあれば削除
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw RecordingError.segmentMergeFailed("Failed to create export session")
        }

        exportSession.outputURL = url
        exportSession.outputFileType = .wav

        await exportSession.export()

        guard exportSession.status == .completed else {
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw RecordingError.segmentMergeFailed("Export failed: \(errorMessage)")
        }
    }

    /// セグメントファイルを削除
    private func cleanupSegmentFiles() {
        for url in segmentURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// 全状態をリセット
    private func cleanup() {
        segmentURLs = []
        currentSegmentIndex = 0
        baseIdentifier = ""
        accumulatedDuration = 0
        recorder = nil
        startTime = nil
    }
}
