//
//  LocalizedString.swift
//  WhisperPad
//

import Foundation

extension String {
    /// Initialize a localized string from a LocalizationKey constant
    ///
    /// This initializer enables type-safe localization with String Catalogs in SPM.
    /// Falls back to the key itself if no localization is found.
    ///
    /// Usage:
    /// ```swift
    /// Text(String(localized: LocalizationKey.generalLanguage))
    /// ```
    ///
    /// - Parameter key: The localization key from LocalizationKey
    init(localized key: String) {
        self = NSLocalizedString(key, bundle: .main, comment: "")
    }
}
