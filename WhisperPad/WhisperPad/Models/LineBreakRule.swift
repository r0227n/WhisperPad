//
//  LineBreakRule.swift
//  WhisperPad
//

import Foundation

/// 改行ルール
struct LineBreakRule: Codable, Equatable, Identifiable, Sendable {
    /// ルールID
    var id: UUID = .init()

    /// トリガー文字（改行のきっかけとなる文字列）
    var character: String

    /// ルールが有効かどうか
    var isEnabled: Bool = true

    /// 優先順位（低い値ほど優先）
    var priority: Int

    /// 改行位置
    var position: BreakPosition = .after

    /// 改行位置
    enum BreakPosition: String, Codable, CaseIterable, Sendable {
        /// 文字の直後に改行
        case after
        /// 文字の直前に改行
        case before
    }
}
