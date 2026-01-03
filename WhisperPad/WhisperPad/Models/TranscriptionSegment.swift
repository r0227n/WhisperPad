//
//  TranscriptionSegment.swift
//  WhisperPad
//

import Foundation

/// 文字起こしセグメント
struct TranscriptionSegment: Sendable {
    /// テキスト
    let text: String

    /// 開始時刻（秒）
    let start: Double

    /// 終了時刻（秒）
    let end: Double
}
