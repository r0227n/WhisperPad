//
//  String+WhisperTokens.swift
//  WhisperPad
//

import Foundation

extension String {
    /// Removes Whisper special tokens in the format <|...|>
    ///
    /// This method removes all Whisper-specific tokens that appear in transcription output,
    /// such as <|startoftranscript|>, <|ja|>, <|transcribe|>, <|0.00|>, etc.
    ///
    /// - Example:
    ///   ```
    ///   "<|ja|>こんにちは<|0.00|>".removingWhisperTokens() // "こんにちは"
    ///   ```
    ///
    /// - Returns: Text with all Whisper special tokens removed
    func removingWhisperTokens() -> String {
        // Remove all <|...|> patterns
        self.replacingOccurrences(
            of: "<\\|[^|]*\\|>",
            with: "",
            options: .regularExpression
        )
    }
}
