//
//  LineBreakSettings.swift
//  WhisperPad
//

import Foundation

/// 改行設定
struct LineBreakSettings: Codable, Equatable, Sendable {
    /// 改行機能が有効かどうか
    var isEnabled: Bool = false

    /// セグメント区切りで改行するかどうか
    var useSegmentBoundaries: Bool = true

    /// 無音検出で改行するかどうか
    var useSilenceDetection: Bool = false

    /// 無音のしきい値（秒）
    /// セグメント間のタイムギャップがこの値以上の場合に改行
    var silenceThreshold: Double = 1.0

    /// 文字ベースの改行ルール
    var characterRules: [LineBreakRule] = Self.defaultCharacterRules

    /// デフォルトの文字ルール
    static let defaultCharacterRules: [LineBreakRule] = [
        LineBreakRule(character: "。", priority: 0),
        LineBreakRule(character: "！", priority: 1),
        LineBreakRule(character: "？", priority: 2),
        LineBreakRule(character: ".", priority: 3),
        LineBreakRule(character: "!", priority: 4),
        LineBreakRule(character: "?", priority: 5)
    ]

    /// デフォルト設定
    static let `default` = LineBreakSettings()
}
