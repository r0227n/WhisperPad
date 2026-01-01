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

    // MARK: - State

    private var confirmedSegments: [String] = []
    private var pendingSegment: String = ""
    private var previousResults: [String] = []
    private var confirmationCount: Int = 2
    private var language: String? = "ja"
    private var accumulatedSamples: [Float] = []

    // MARK: - Initialization

    /// ストリーミング文字起こしを初期化
    ///
    /// テキスト状態をリセットし、WhisperKitManager の共有インスタンスを使用します。
    /// WhisperKit の初期化は AppReducer で行われるため、ここでは状態のリセットのみ行います。
    func initialize(modelName: String?, confirmationCount: Int = 2, language: String? = "ja") async throws {
        logger.info("Initializing StreamingTranscriptionService with model: \(modelName ?? "default")")

        // テキスト状態をリセット
        confirmedSegments.removeAll()
        pendingSegment = ""
        previousResults.removeAll()
        accumulatedSamples.removeAll()

        self.confirmationCount = confirmationCount
        self.language = language

        // WhisperKitManager が初期化済みかチェック
        guard await WhisperKitManager.shared.isReady else {
            // まだ初期化されていない場合は初期化を試みる
            logger.info("WhisperKit not ready, initializing...")
            do {
                try await WhisperKitManager.shared.initialize(modelName: modelName)
                logger.info("WhisperKit initialized successfully")
            } catch {
                logger.error("Failed to initialize WhisperKit: \(error.localizedDescription)")
                throw StreamingTranscriptionError.initializationFailed(error.localizedDescription)
            }
            return
        }

        logger.info("WhisperKit already initialized, reusing existing instance")
    }

    /// 音声チャンクを処理して文字起こし結果を返す
    func processAudioChunk(_ samples: [Float]) async throws -> TranscriptionProgress {
        guard let whisperKit = await WhisperKitManager.shared.getWhisperKit() else {
            throw StreamingTranscriptionError.initializationFailed("WhisperKit not initialized")
        }

        // サンプルを蓄積
        accumulatedSamples.append(contentsOf: samples)

        // 最低限のサンプル数が必要（約1秒分 = 16000サンプル）
        guard accumulatedSamples.count >= 16000 else {
            return TranscriptionProgress(
                confirmedText: confirmedSegments.joined(separator: " "),
                pendingText: pendingSegment,
                decodingText: "",
                tokensPerSecond: 0
            )
        }

        do {
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
            let transcribedText = results.map(\.text).joined(separator: " ")
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
                confirmedText: confirmedSegments.joined(separator: " "),
                pendingText: pendingSegment,
                decodingText: transcribedText,
                tokensPerSecond: tokensPerSecond
            )
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            throw StreamingTranscriptionError.processingFailed(error.localizedDescription)
        }
    }

    /// 文字起こしを終了し、最終結果を返す
    func finalize() async throws -> String {
        // 残りのサンプルを処理
        if !accumulatedSamples.isEmpty,
           let whisperKit = await WhisperKitManager.shared.getWhisperKit() {
            var options = DecodingOptions()
            options.language = language
            options.task = .transcribe

            let results = try await whisperKit.transcribe(
                audioArray: accumulatedSamples,
                decodeOptions: options
            )

            let finalText = results.map(\.text).joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !finalText.isEmpty {
                confirmedSegments.append(finalText)
            }
        }

        let result = confirmedSegments.joined(separator: " ")
        logger.info("Finalized transcription: \(result.prefix(50))...")
        return result
    }

    /// 状態をリセット
    func reset() async {
        confirmedSegments.removeAll()
        pendingSegment = ""
        previousResults.removeAll()
        accumulatedSamples.removeAll()
        logger.info("Service reset")
    }

    // MARK: - Private Methods

    private func updateConfirmation(newText: String) -> Bool {
        previousResults.append(newText)

        if previousResults.count > confirmationCount {
            previousResults.removeFirst()
        }

        guard previousResults.count >= confirmationCount else {
            return false
        }

        guard let first = previousResults.first else {
            return false
        }

        return previousResults.allSatisfy { $0 == first }
    }
}
