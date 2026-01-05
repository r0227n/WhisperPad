//
//  AppDelegate+MenuDelegate.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Dependencies

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        #if DEBUG
        if menu == statusMenu {
            updatePermissionMenuItems()
            updateOutputMenuItems()
        }
        #endif
    }

    /// 現在のロケール設定から言語コードを解決
    ///
    /// - Returns: 言語コード（"en" または "ja"）
    func resolveLanguageCode() -> String {
        if let identifier = store.settings.settings.general.preferredLocale.identifier {
            return identifier
        }
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        return Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
    }
}
