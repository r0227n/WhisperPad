//
//  TranscriptionSettings.swift
//  WhisperPad
//

import Foundation

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

// MARK: - TranscriptionLanguage

extension TranscriptionSettings {
    /// 認識言語
    enum TranscriptionLanguage: String, Codable, CaseIterable, Sendable {
        /// 自動検出
        case auto

        /// 日本語
        case ja

        /// 英語
        case en

        /// 中国語
        case zh

        /// 韓国語
        case ko

        /// フランス語
        case fr

        /// ドイツ語
        case de

        /// スペイン語
        case es

        /// 表示名
        var displayName: String {
            switch self {
            case .auto:
                "自動検出"
            case .ja:
                "日本語"
            case .en:
                "English"
            case .zh:
                "中文"
            case .ko:
                "한국어"
            case .fr:
                "Français"
            case .de:
                "Deutsch"
            case .es:
                "Español"
            }
        }

        /// WhisperKit で使用する言語コード
        var whisperCode: String? {
            switch self {
            case .auto:
                nil
            default:
                rawValue
            }
        }
    }
}
