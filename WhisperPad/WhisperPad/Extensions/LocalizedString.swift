//
//  LocalizedString.swift
//  WhisperPad
//

import Foundation

extension String {
    /// Initialize a localized string from a LocalizationKey constant
    ///
    /// This initializer enables type-safe localization with String Catalogs in SPM
    /// while supporting runtime language switching through LocalizationBundleManager.
    ///
    /// Usage:
    /// ```swift
    /// Text(String(localized: LocalizationKey.generalLanguage))
    /// ```
    ///
    /// - Parameter key: The localization key from LocalizationKey
    init(localized key: String) {
        self = LocalizationBundleManager.shared.localizedString(key)
    }
}
