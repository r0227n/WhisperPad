//
//  TranscriptionSettings.swift
//  WhisperPad
//

import Foundation
import SwiftUI

/// 文字起こし設定
///
/// WhisperKit を使用した音声認識の設定を管理します。
struct TranscriptionSettings: Codable, Equatable, Sendable {
    /// 使用するモデル名
    var modelName: String = "openai_whisper-small"

    /// 認識言語
    var language: TranscriptionLanguage = .auto

    /// カスタムストレージ URL（nil の場合はデフォルト）
    var customStorageURL: URL?

    /// Security-Scoped Bookmark データ
    var storageBookmarkData: Data?

    /// デフォルト設定
    static let `default` = TranscriptionSettings()
}
