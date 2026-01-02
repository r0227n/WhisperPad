//
//  TranscriptionSettings.swift
//  WhisperPad
//

import Foundation

/// Transcription settings
///
/// Manages speech recognition settings using WhisperKit.
struct TranscriptionSettings: Codable, Equatable, Sendable {
    /// Model name to use
    var modelName: String = "openai_whisper-small"

    /// Recognition language
    var language: TranscriptionLanguage = .auto

    /// Custom storage URL (nil for default)
    var customStorageURL: URL?

    /// Security-Scoped Bookmark data
    var storageBookmarkData: Data?

    /// Default settings
    static let `default` = TranscriptionSettings()
}

// MARK: - TranscriptionLanguage

extension TranscriptionSettings {
    /// Recognition language
    enum TranscriptionLanguage: String, Codable, CaseIterable, Sendable {
        /// Auto detect
        case auto

        /// Japanese
        case ja

        /// English
        case en

        /// Chinese
        case zh

        /// Korean
        case ko

        /// French
        case fr

        /// German
        case de

        /// Spanish
        case es

        /// Display name (native language names are not localized)
        @MainActor
        var displayName: String {
            switch self {
            case .auto:
                L10n.get(.transcriptionLanguageAuto)
            case .ja:
                L10n.get(.transcriptionLanguageJapanese)
            case .en:
                L10n.get(.transcriptionLanguageEnglish)
            case .zh:
                L10n.get(.transcriptionLanguageChinese)
            case .ko:
                L10n.get(.transcriptionLanguageKorean)
            case .fr:
                L10n.get(.transcriptionLanguageFrench)
            case .de:
                L10n.get(.transcriptionLanguageGerman)
            case .es:
                L10n.get(.transcriptionLanguageSpanish)
            }
        }

        /// Language code for WhisperKit
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
