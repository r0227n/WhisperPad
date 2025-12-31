//
//  TranscriptionProgress.swift
//  WhisperPad
//

import Foundation

/// ストリーミング文字起こしの進捗状態
///
/// リアルタイム文字起こし中のテキスト状態と処理速度を保持します。
struct TranscriptionProgress: Equatable, Sendable {
    /// 確定したテキスト（変更されない）
    let confirmedText: String

    /// 未確定のテキスト（確定待ち）
    let pendingText: String

    /// デコード中のテキスト（プレビュー）
    let decodingText: String

    /// 処理速度（トークン/秒）
    let tokensPerSecond: Double

    /// 空の進捗
    static let empty = TranscriptionProgress(
        confirmedText: "",
        pendingText: "",
        decodingText: "",
        tokensPerSecond: 0
    )
}
