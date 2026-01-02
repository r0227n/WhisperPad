//
//  LocalizationManager.swift
//  WhisperPad
//

import Foundation
import SwiftUI

/// Manages application localization with dynamic language switching
@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage)
        {
            currentLanguage = language
        } else {
            // Default to English
            currentLanguage = .english
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    func localizedString(for key: LocalizedStringKey) -> String {
        key.localized(for: currentLanguage)
    }
}

// MARK: - Environment Key

private struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
