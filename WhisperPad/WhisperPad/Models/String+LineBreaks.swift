//
//  String+LineBreaks.swift
//  WhisperPad
//

import Foundation

extension String {
    /// Adds line breaks after Japanese sentence-ending periods (。)
    ///
    /// Uses regex to insert newline after 。 only if not already followed by newline.
    /// This preserves existing line breaks from silence gap detection.
    ///
    /// - Returns: Text with line breaks after each 。
    func addingJapaneseSentenceBreaks() -> String {
        // Replace 。 followed by any character (except newline) with 。\n
        self.replacingOccurrences(
            of: "。(?!\\n)", // 。 not followed by newline
            with: "。\n",
            options: .regularExpression
        )
    }
}
