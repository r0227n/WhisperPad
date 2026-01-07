//
//  WhisperKitManager+Transcription.swift
//  WhisperPad
//

import Foundation
import os
import WhisperKit

// MARK: - Transcription

extension WhisperKitManager {
    /// 音声ファイルを文字起こし
    func transcribe(audioURL: URL, language: String?) async throws -> String {
        guard let whisperKit = getWhisperKit() else {
            logger.error("Transcription attempted without initialized WhisperKit")
            throw TranscriptionError.modelNotLoaded
        }

        logger.info("Starting transcription for: \(audioURL.lastPathComponent)")

        do {
            // DecodingOptions を設定
            var options = DecodingOptions()
            options.language = language
            options.task = .transcribe
            options.verbose = false

            // 文字起こしを実行
            let results = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: options
            )

            // Phase 1: Combine segments with silence gap detection
            let transcribedText = combineSegmentsWithSilenceBreaks(results: results)

            // Phase 2: Remove Whisper special tokens
            let cleanedText = transcribedText.removingWhisperTokens()

            // Phase 3: Apply Japanese sentence breaks
            let textWithLineBreaks = cleanedText.addingJapaneseSentenceBreaks()

            let trimmedText = textWithLineBreaks.trimmingCharacters(in: .whitespacesAndNewlines)

            logger.info("Transcription completed: \(trimmedText.prefix(50))...")
            return trimmedText
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
    }

    /// Combine transcription segments with line breaks at silence gaps
    ///
    /// Detects silence gaps (>=1.0 second) between segments and inserts line breaks.
    /// - Parameter results: Transcription results from WhisperKit
    /// - Returns: Combined text with silence-based line breaks
    private func combineSegmentsWithSilenceBreaks(results: [TranscriptionResult]) -> String {
        let silenceThreshold: Float = 1.0 // 1 second

        guard !results.isEmpty else { return "" }

        // Extract all segments from all results
        let allSegments = results.flatMap(\.segments)

        guard !allSegments.isEmpty else { return "" }

        var combinedText = ""

        for (index, segment) in allSegments.enumerated() {
            // Add segment text
            combinedText += segment.text

            // Check for silence gap after this segment
            if index < allSegments.count - 1 {
                let nextSegment = allSegments[index + 1]
                let gap = nextSegment.start - segment.end

                if gap >= silenceThreshold {
                    // Silence gap detected - add line break
                    logger.debug("Silence gap detected: \(gap)s at segment \(index)")
                    combinedText += "\n"
                }
            }
        }

        return combinedText
    }
}
