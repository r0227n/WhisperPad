//
//  AudioEngineRecorder.swift
//  WhisperPad
//

import AppKit
@preconcurrency import AVFAudio
import AVFoundation

/// AVAudioEngine を使用した音声録音マネージャー
///
/// - Note: macOS では録音開始時に以下のようなログが出力されることがありますが、
///   これらは CoreAudio の内部ログであり、録音機能には影響しません:
///   - "AddInstanceForFactory: No factory registered for id"
///   - "Reporter disconnected"
///   - "throwing -10877"
///   参考: https://developer.apple.com/forums/thread/129136
@MainActor
final class AudioEngineRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private var startTime: Date?
    private var lastAudioLevel: Float = -160.0 // 無音レベル

    // シングルトンインスタンス
    static let shared = AudioEngineRecorder()

    // WhisperKit 推奨設定
    static let targetSampleRate: Double = 16000.0
    static let targetChannels: AVAudioChannelCount = 1
    static let targetBitDepth: UInt32 = 16

    /// 出力フォーマット (16kHz, mono, 16-bit PCM)
    var outputFormat: AVAudioFormat {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.targetSampleRate,
            channels: Self.targetChannels,
            interleaved: true
        ) else {
            fatalError("Failed to create output audio format with standard parameters")
        }
        return format
    }

    /// 録音中かどうか
    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }

    /// 現在の録音時間
    var currentTime: TimeInterval? {
        guard isRecording, let startTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    /// 現在の音声レベル (dB)
    var currentLevel: Float? {
        guard isRecording else { return nil }
        return lastAudioLevel
    }

    init() {}

    /// Pre-warm the audio engine to trigger CoreAudio initialization.
    ///
    /// macOS では AVAudioEngine の初期化時に以下のログが出力されることがあります：
    /// - "AddInstanceForFactory: No factory registered for id"
    /// - "Reporter disconnected"
    /// - "throwing -10877"
    ///
    /// これらは CoreAudio HAL (Hardware Abstraction Layer) の内部ログであり、
    /// 録音機能には影響しません。アプリ起動時にこのメソッドを呼び出すことで、
    /// 録音開始時ではなく起動時に警告を発生させます。
    ///
    /// - SeeAlso: https://developer.apple.com/forums/thread/129136
    func prewarm() {
        let engine = AVAudioEngine()
        _ = engine.inputNode  // Triggers CoreAudio HAL initialization
        engine.stop()
    }

    /// マイク権限を要求
    func requestPermission() async -> Bool {
        // メニューバーアプリでダイアログを表示するためにアプリをアクティブ化
        NSApp.activate(ignoringOtherApps: true)

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// 録音を開始
    /// - Parameter url: 録音ファイルの保存先 URL
    func startRecording(url: URL) throws {
        // 既存の録音を停止
        stopRecording()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        // WhisperKit パターン: inputFormat からサンプルレート、outputFormat からその他を取得
        // これにより、macOS での CoreAudio 初期化問題を回避
        let hardwareSampleRate = inputNode.inputFormat(forBus: 0).sampleRate
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // サンプルレートの検証（マイク権限がない場合は 0 になる）
        try validateHardwareSampleRate(hardwareSampleRate)

        // フォーマットを再構築（WhisperKit パターン）
        let nodeFormat = try createNodeFormat(from: inputFormat, sampleRate: hardwareSampleRate)

        // 保存先ディレクトリを準備
        try prepareDirectory(for: url)

        // 出力ファイル作成
        let file = try createAudioFile(at: url)

        // サンプルレート変換用コンバーター（nodeFormat から作成）
        let converter = try createConverter(from: nodeFormat)

        // 入力タップをインストールしてエンジンを開始
        try startEngine(engine, inputNode: inputNode, nodeFormat: nodeFormat, converter: converter, file: file)

        self.audioEngine = engine
        self.audioFile = file
        self.converter = converter
        self.startTime = Date()
    }

    /// ハードウェアサンプルレートを検証
    private func validateHardwareSampleRate(_ sampleRate: Double) throws {
        guard sampleRate > 0 else {
            throw RecordingError.audioEngineStartFailed(
                "Invalid hardware sample rate (\(sampleRate)). " +
                "Microphone permission may not be granted or no audio input device."
            )
        }
    }

    /// ノードフォーマットを作成（WhisperKit パターン）
    private func createNodeFormat(from inputFormat: AVAudioFormat, sampleRate: Double) throws -> AVAudioFormat {
        guard let format = AVAudioFormat(
            commonFormat: inputFormat.commonFormat,
            sampleRate: sampleRate,
            channels: inputFormat.channelCount,
            interleaved: inputFormat.isInterleaved
        ) else {
            throw RecordingError.audioEngineStartFailed(
                "Failed to create node format (sampleRate=\(sampleRate), " +
                "channels=\(inputFormat.channelCount))"
            )
        }
        return format
    }

    /// 保存先ディレクトリを準備
    private func prepareDirectory(for url: URL) throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    /// オーディオファイルを作成
    private func createAudioFile(at url: URL) throws -> AVAudioFile {
        do {
            return try AVAudioFile(forWriting: url, settings: outputFormat.settings)
        } catch {
            throw RecordingError.audioFileCreationFailed(
                "Failed to create audio file at \(url.path): \(error.localizedDescription)"
            )
        }
    }

    /// オーディオコンバーターを作成
    private func createConverter(from inputFormat: AVAudioFormat) throws -> AVAudioConverter {
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            let inputInfo = "\(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch"
            let outputInfo = "\(outputFormat.sampleRate)Hz, \(outputFormat.channelCount)ch"
            throw RecordingError.audioConverterFailed(
                "Could not create converter. Input: \(inputInfo), Output: \(outputInfo)"
            )
        }
        return converter
    }

    /// エンジンを開始
    private func startEngine(
        _ engine: AVAudioEngine,
        inputNode: AVAudioInputNode,
        nodeFormat: AVAudioFormat,
        converter: AVAudioConverter,
        file: AVAudioFile
    ) throws {
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nodeFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, converter: converter, file: file)
        }
        do {
            // WhisperKit パターン: prepare() を呼び出してから start()
            engine.prepare()
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw RecordingError.audioEngineStartFailed(
                "Failed to start audio engine: \(error.localizedDescription)"
            )
        }
    }

    /// 録音を停止
    func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        converter = nil
        startTime = nil
        lastAudioLevel = -160.0
    }

    /// オーディオバッファを処理してファイルに書き込む
    private func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter?,
        file: AVAudioFile
    ) {
        // 音声レベル計算
        updateAudioLevel(from: buffer)

        // フォーマット変換してファイルに書き込み
        guard let converter,
            let convertedBuffer = convertBuffer(buffer, using: converter)
        else {
            return
        }

        do {
            try file.write(from: convertedBuffer)
        } catch {
            // エラーログ（必要に応じて実装）
        }
    }

    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter
    ) -> AVAudioPCMBuffer? {
        let outputFrameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * outputFormat.sampleRate / buffer.format.sampleRate
        )

        guard
            let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputFrameCapacity
            )
        else {
            return nil
        }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status == .haveData else { return nil }
        return outputBuffer
    }

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for frameIndex in 0..<frameLength {
            sum += channelData[frameIndex] * channelData[frameIndex]
        }

        let rms = sqrt(sum / Float(frameLength))
        let decibels = 20 * log10(max(rms, 0.000001))

        DispatchQueue.main.async { [weak self] in
            self?.lastAudioLevel = decibels
        }
    }
}
