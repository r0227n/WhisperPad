//
//  L10n.swift
//  WhisperPad
//

import Foundation

/// Shorthand for accessing localized strings
/// Usage: L10n.get(.settingsTabGeneral)
enum L10n {
    /// Get localized string for the current language
    @MainActor
    static func get(_ key: LocalizedStringKey) -> String {
        LocalizationManager.shared.localizedString(for: key)
    }

    /// Get localized string for a specific language
    static func get(_ key: LocalizedStringKey, for language: AppLanguage) -> String {
        key.localized(for: language)
    }
}
