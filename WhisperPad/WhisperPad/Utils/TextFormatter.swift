//
//  TextFormatter.swift
//  WhisperPad
//

import Foundation

/// テキストフォーマッター
enum TextFormatter {
    /// 改行設定に基づいてテキストをフォーマット
    ///
    /// - Parameters:
    ///   - segments: 文字起こしセグメント配列
    ///   - settings: 改行設定
    /// - Returns: フォーマット済みテキスト
    static func format(
        segments: [TranscriptionSegment],
        settings: LineBreakSettings
    ) -> String {
        guard settings.isEnabled else {
            // 設定無効の場合は全セグメントを連結
            return segments.map(\.text).joined(separator: " ")
        }

        var lines: [String] = []
        var currentLine = ""

        for (index, segment) in segments.enumerated() {
            // セグメント区切りチェック
            if settings.useSegmentBoundaries, !currentLine.isEmpty {
                lines.append(currentLine.trimmingCharacters(in: .whitespaces))
                currentLine = segment.text
                continue
            }

            // 無音検出チェック
            if settings.useSilenceDetection, index > 0 {
                let previousSegment = segments[index - 1]
                let gap = segment.start - previousSegment.end

                if gap >= settings.silenceThreshold, !currentLine.isEmpty {
                    lines.append(currentLine.trimmingCharacters(in: .whitespaces))
                    currentLine = segment.text
                    continue
                }
            }

            // 文字ルールに基づく改行処理
            if !settings.characterRules.isEmpty {
                let processedText = applyCharacterRules(
                    to: segment.text,
                    rules: settings.characterRules
                )
                currentLine += (currentLine.isEmpty ? "" : " ") + processedText

                // 改行が含まれている場合は分割
                let splitLines = currentLine.components(separatedBy: "\n")
                if splitLines.count > 1 {
                    lines.append(contentsOf: splitLines.dropLast().map {
                        $0.trimmingCharacters(in: .whitespaces)
                    })
                    currentLine = splitLines.last ?? ""
                }
            } else {
                currentLine += (currentLine.isEmpty ? "" : " ") + segment.text
            }
        }

        // 最後の行を追加
        if !currentLine.isEmpty {
            lines.append(currentLine.trimmingCharacters(in: .whitespaces))
        }

        return lines.joined(separator: "\n")
    }

    /// 文字ルールを適用
    ///
    /// - Parameters:
    ///   - text: 処理対象のテキスト
    ///   - rules: 適用する改行ルール配列
    /// - Returns: ルールが適用されたテキスト
    private static func applyCharacterRules(
        to text: String,
        rules: [LineBreakRule]
    ) -> String {
        var result = text

        // 優先順位順にソート（有効なルールのみ）
        let enabledRules = rules
            .filter(\.isEnabled)
            .sorted { $0.priority < $1.priority }

        for rule in enabledRules {
            let replacement = switch rule.position {
            case .after:
                "\(rule.character)\n"
            case .before:
                "\n\(rule.character)"
            }

            result = result.replacingOccurrences(
                of: rule.character,
                with: replacement
            )
        }

        return result
    }
}
