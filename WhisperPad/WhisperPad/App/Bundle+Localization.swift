//
//  Bundle+Localization.swift
//  WhisperPad
//

import Foundation

// MARK: - Localization Helpers

/// xcstrings ファイルから指定されたロケールに基づいて翻訳を取得する
extension Bundle {
    func localizedString(forKey key: String, preferredLanguage: String) -> String {
        // For xcstrings files, try to get bundle for preferred language
        if let path = self.path(forResource: preferredLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }

        // Fallback to main bundle (will use sourceLanguage from xcstrings)
        return self.localizedString(forKey: key, value: nil, table: nil)
    }
}
