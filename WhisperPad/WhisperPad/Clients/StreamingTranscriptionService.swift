//
//  StreamingTranscriptionService.swift
//  WhisperPad
//

import Foundation
import OSLog
import WhisperKit

/// リアルタイム文字起こし actor
///
/// 音声チャンクを受け取り、リアルタイムで文字起こしを行います。
/// 確定ロジック: 同じテキストが confirmationCount 回連続で出力されると確定
actor StreamingTranscriptionService {
    // MARK: - Constants

    private let logger = Logger(
        subsystem: "com.whisperpad",
        category: "StreamingTranscriptionService"
    )

    private static let defaultModelRepo = "argmaxinc/whisperkit-coreml"

    /// デフォルトのモデル保存先ディレクトリ（TranscriptionServiceと同じパス）
    private static var modelsDirectory: URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Application Support directory not found")
        }
        return appSupport.appendingPathComponent("WhisperPad/models", isDirectory: true)
    }

    // MARK: - Buffer Management Constants

    private enum BufferLimits {
        /// 警告閾値: 20秒分のサンプル (16000 samples/sec × 20)
        static let warningThreshold: Int = 320_000

        /// 最大閾値: 30秒分のサンプル (16000 samples/sec × 30)
        static let maximumThreshold: Int = 480_000
    }

    // MARK: - State

    private var confirmedSegments: [String] = []
    private var pendingSegment: String = ""
    private var previousResults: [String] = []
    private var confirmationCount: Int = 2
    private var language: String? = "ja"
    private var accumulatedSamples: [Float] = []

    // 確認ロジック改善用
    private var lastConfirmationTime: Date?
    private var confirmationTimeout: TimeInterval = 5.0 // 5秒でタイムアウト

    // MARK: - Initialization

    /// ストリーミング文字起こしサービスを初期化
    ///
    /// テキスト状態をリセットし、WhisperKitManager の共有インスタンスを使用します。
    /// 注意: このメソッドを呼び出す前に、Feature 層で WhisperKit を初期化しておく必要があります。
    /// WhisperKit が初期化されていない場合、エラーをスローします。
    func initialize(modelName: String?, confirmationCount: Int = 2, language: String? = nil) async throws {
        logger.info("Initializing StreamingTranscriptionService")

        // テキスト状態をリセット
        confirmedSegments.removeAll()
        pendingSegment = ""
        previousResults.removeAll()
        accumulatedSamples.removeAll()
        lastConfirmationTime = nil

        self.confirmationCount = confirmationCount
        self.language = language

        // WhisperKit が初期化済みであることを確認（Feature 層で初期化済みのはず）
        guard await WhisperKitManager.shared.isReady else {
            logger.error(
                "WhisperKit is not ready. Feature layer should initialize WhisperKit before calling this method."
            )
            throw StreamingTranscriptionError.initializationFailed("WhisperKit is not initialized")
        }

        logger.info("StreamingTranscriptionService initialized successfully")
    }

    /// 音声チャンクを処理して文字起こし結果を返す
    func processAudioChunk(_ samples: [Float]) async throws -> TranscriptionProgress {
        guard let whisperKit = await WhisperKitManager.shared.getWhisperKit() else {
            throw StreamingTranscriptionError.initializationFailed("WhisperKit not initialized")
        }

        // サンプルを蓄積
        accumulatedSamples.append(contentsOf: samples)

        // バッファオーバーフロー検出
        try checkBufferOverflow()

        // 最低限のサンプル数が必要（約1秒分 = 16000サンプル）
        guard accumulatedSamples.count >= 16000 else {
            return TranscriptionProgress(
                confirmedText: confirmedSegments.joined(separator: "\n"),
                pendingText: pendingSegment,
                decodingText: "",
                tokensPerSecond: 0
            )
        }

        do {
            return try await performTranscription(whisperKit: whisperKit)
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            // エラー時にバッファをクリアしてメモリリーク防止
            accumulatedSamples.removeAll()
            throw StreamingTranscriptionError.processingFailed(error.localizedDescription)
        }
    }

    /// 文字起こしを終了し、最終結果を返す
    func finalize() async throws -> String {
        // If there's pending text, confirm it (avoid re-transcribing)
        if !pendingSegment.isEmpty {
            confirmedSegments.append(pendingSegment)
            pendingSegment = ""
        } else if !accumulatedSamples.isEmpty,
                  let whisperKit = await WhisperKitManager.shared.getWhisperKit() {
            // Only transcribe if there's no pending segment
            // (meaning new samples arrived after the last transcription)
            var options = DecodingOptions()
            options.language = language
            options.task = .transcribe

            let results = try await whisperKit.transcribe(
                audioArray: accumulatedSamples,
                decodeOptions: options
            )

            let finalText = results.map(\.text).joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !finalText.isEmpty {
                confirmedSegments.append(finalText)
            }
        }

        let result = confirmedSegments.joined(separator: "\n")
        logger.info("Finalized transcription: \(result.prefix(50))...")
        return result
    }

    /// 状態をリセット
    func reset() async {
        confirmedSegments.removeAll()
        pendingSegment = ""
        previousResults.removeAll()
        accumulatedSamples.removeAll()
        lastConfirmationTime = nil
        logger.info("Service reset")
    }

    // MARK: - Private Methods

    /// バッファオーバーフローをチェック
    private func checkBufferOverflow() throws {
        let bufferSize = accumulatedSamples.count
        if bufferSize >= BufferLimits.maximumThreshold {
            logger.error(
                "Buffer overflow: \(bufferSize) samples exceeds max \(BufferLimits.maximumThreshold)"
            )
            accumulatedSamples.removeAll()
            throw StreamingTranscriptionError.bufferOverflow
        } else if bufferSize >= BufferLimits.warningThreshold {
            logger.warning(
                "Buffer approaching limit: \(bufferSize) samples (warning: \(BufferLimits.warningThreshold))"
            )
        }
    }

    /// 文字起こし処理を実行
    private func performTranscription(whisperKit: WhisperKit) async throws -> TranscriptionProgress {
        var options = DecodingOptions()
        options.language = language
        options.task = .transcribe
        options.verbose = false

        let startTime = CFAbsoluteTimeGetCurrent()

        // 蓄積されたサンプルを文字起こし
        let results = try await whisperKit.transcribe(
            audioArray: accumulatedSamples,
            decodeOptions: options
        )

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        // 結果を結合
        let transcribedText = results.map(\.text).joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // トークン数を概算（文字数ベース: 1トークン ≒ 2文字と仮定）
        let estimatedTokenCount = transcribedText.count / 2
        let tokensPerSecond = duration > 0 ? Double(estimatedTokenCount) / duration : 0

        // 確定ロジック
        let isConfirmed = updateConfirmation(newText: transcribedText)

        if isConfirmed, !transcribedText.isEmpty {
            confirmedSegments.append(transcribedText)
            pendingSegment = ""
            previousResults.removeAll()
            accumulatedSamples.removeAll()
        } else {
            pendingSegment = transcribedText
        }

        return TranscriptionProgress(
            confirmedText: confirmedSegments.joined(separator: "\n"),
            pendingText: pendingSegment,
            decodingText: transcribedText,
            tokensPerSecond: tokensPerSecond
        )
    }

    private func updateConfirmation(newText: String) -> Bool {
        let now = Date()

        // タイムアウトチェック
        if let lastTime = lastConfirmationTime,
           now.timeIntervalSince(lastTime) >= confirmationTimeout,
           !newText.isEmpty {
            logger.info("Confirmation timeout reached, auto-confirming text")
            lastConfirmationTime = now
            return true
        }

        previousResults.append(newText)

        if previousResults.count > confirmationCount {
            previousResults.removeFirst()
        }

        guard previousResults.count >= confirmationCount else {
            if lastConfirmationTime == nil {
                lastConfirmationTime = now
            }
            return false
        }

        guard let first = previousResults.first else {
            return false
        }

        // 最小文字数チェック（日本語は2文字以上、その他は3文字以上）
        let minLength = (language == "ja") ? 2 : 3
        guard first.count >= minLength else {
            return false
        }

        // 完全一致チェック
        let allMatch = previousResults.allSatisfy { $0 == first }
        if allMatch {
            lastConfirmationTime = now
            return true
        }

        // 類似度チェック（オプション: 将来的な拡張）
        // 現時点では完全一致のみ

        return false
    }
}
