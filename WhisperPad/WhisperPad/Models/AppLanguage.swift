//
//  AppLanguage.swift
//  WhisperPad
//

import Foundation

/// Supported application languages
enum AppLanguage: String, CaseIterable, Sendable, Codable {
    case english = "en"
    case japanese = "ja"

    /// Display name for the language (shown in native language)
    var displayName: String {
        switch self {
        case .english:
            "English"
        case .japanese:
            "日本語"
        }
    }

    /// Locale identifier
    var localeIdentifier: String {
        rawValue
    }
}
