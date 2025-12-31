//
//  StreamingStatus.swift
//  WhisperPad
//

import Foundation

/// ストリーミング文字起こしのステータス
///
/// リアルタイム文字起こしの現在の状態を表します。
enum StreamingStatus: Equatable, Sendable {
    /// 待機中
    case idle

    /// 初期化中
    case initializing

    /// 録音中
    ///
    /// - Parameters:
    ///   - duration: 録音経過時間（秒）
    ///   - tokensPerSecond: 処理速度（トークン/秒）
    case recording(duration: TimeInterval, tokensPerSecond: Double)

    /// 処理中
    case processing

    /// 完了
    ///
    /// - Parameter text: 確定されたテキスト
    case completed(text: String)

    /// エラー
    ///
    /// - Parameter message: エラーメッセージ
    case error(String)
}
