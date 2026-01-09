//
//  TranscriptionModelState.swift
//  WhisperPad
//

import Foundation

/// モデルの状態
enum TranscriptionModelState: Equatable, Sendable {
    /// 未読み込み
    case unloaded
    /// ダウンロード中（進捗率）
    case downloading(progress: Double)
    /// 読み込み中
    case loading
    /// 読み込み完了
    case loaded
    /// エラー
    case error(String)
}
