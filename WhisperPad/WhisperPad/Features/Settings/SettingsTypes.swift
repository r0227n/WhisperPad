//
//  SettingsTypes.swift
//  WhisperPad
//

import Foundation

// MARK: - Settings Tab

/// 設定タブ
enum SettingsTab: String, CaseIterable, Sendable {
    case general
    case icon
    case hotkey
    case recording
    case model

    /// 表示名（ローカライズ済み）
    var displayName: String {
        switch self {
        case .general:
            String(localized: "settings.tab.general", comment: "General")
        case .icon:
            String(localized: "settings.tab.icon", comment: "Icon")
        case .hotkey:
            String(localized: "settings.tab.hotkey", comment: "Shortcuts")
        case .recording:
            String(localized: "settings.tab.recording", comment: "Recording")
        case .model:
            String(localized: "settings.tab.model", comment: "Model")
        }
    }

    /// SF Symbol 名
    var iconName: String {
        switch self {
        case .general:
            "gear"
        case .icon:
            "paintbrush"
        case .hotkey:
            "keyboard"
        case .recording:
            "waveform"
        case .model:
            "cpu"
        }
    }

    /// ローカライズキー
    var localizationKey: String {
        switch self {
        case .general:
            "settings.tab.general"
        case .icon:
            "settings.tab.icon"
        case .hotkey:
            "settings.tab.hotkey"
        case .recording:
            "settings.tab.recording"
        case .model:
            "settings.tab.model"
        }
    }

    /// 指定されたロケールでのローカライズされたタイトルを取得
    ///
    /// - Parameter locale: ローカライズに使用するAppLocale
    /// - Returns: ローカライズされたタイトル文字列
    func localizedTitle(for locale: AppLocale) -> String {
        String(
            localized: String.LocalizationValue(localizationKey),
            bundle: locale.bundle,
            locale: locale.locale
        )
    }
}

// MARK: - HotkeyType Metadata

extension HotkeyType {
    /// ショートカットのカテゴリ
    enum Category: String, CaseIterable, Identifiable {
        case recording
        case cancel

        var id: String { rawValue }

        /// 表示名（ローカライズ済み）
        var displayName: String {
            switch self {
            case .recording:
                String(localized: "hotkey.category.recording", comment: "Recording")
            case .cancel:
                String(localized: "hotkey.category.cancel", comment: "Cancel")
            }
        }

        /// このカテゴリに属するショートカットタイプ
        var hotkeyTypes: [HotkeyType] {
            switch self {
            case .recording:
                [.recording, .recordingPause]
            case .cancel:
                [.cancel]
            }
        }
    }

    /// ショートカットのカテゴリ
    var category: Category {
        switch self {
        case .recording, .recordingPause:
            .recording
        case .cancel:
            .cancel
        }
    }

    /// 表示名（ローカライズ済み）
    var displayName: String {
        switch self {
        case .recording:
            String(localized: "hotkey.type.recording", comment: "Start/Stop Recording")
        case .recordingPause:
            String(localized: "hotkey.type.recording_pause", comment: "Pause/Resume")
        case .cancel:
            String(localized: "hotkey.type.cancel", comment: "Cancel Recording")
        }
    }

    /// 説明（ローカライズ済み）
    var hotkeyDescription: String {
        switch self {
        case .recording:
            String(localized: "hotkey.description.recording", comment: "Start or stop recording")
        case .recordingPause:
            String(localized: "hotkey.description.recording_pause", comment: "Pause or resume recording")
        case .cancel:
            String(localized: "hotkey.description.cancel", comment: "Cancel ongoing recording")
        }
    }

    /// SF Symbol アイコン名
    var iconName: String {
        switch self {
        case .recording:
            "mic.fill"
        case .recordingPause:
            "pause.fill"
        case .cancel:
            "xmark.circle"
        }
    }

    /// 対応するアイコン設定ステータス
    var correspondingIconStatus: IconConfigStatus {
        switch self {
        case .recording:
            .recording
        case .recordingPause:
            .paused
        case .cancel:
            .cancel
        }
    }
}

// MARK: - Localization

import SwiftUI

extension HotkeyType {
    /// ローカライズキー
    var localizedKey: LocalizedStringKey {
        switch self {
        case .recording: "hotkey.type.recording"
        case .recordingPause: "hotkey.type.recording_pause"
        case .cancel: "hotkey.type.cancel"
        }
    }

    /// ローカライズキー（String）
    var localizationKey: String {
        switch self {
        case .recording: "hotkey.type.recording"
        case .recordingPause: "hotkey.type.recording_pause"
        case .cancel: "hotkey.type.cancel"
        }
    }

    /// 説明のローカライズキー
    var descriptionKey: LocalizedStringKey {
        switch self {
        case .recording: "hotkey.description.recording"
        case .recordingPause: "hotkey.description.recording_pause"
        case .cancel: "hotkey.description.cancel"
        }
    }

    /// 説明のローカライズキー（String）
    var descriptionLocalizationKey: String {
        switch self {
        case .recording: "hotkey.description.recording"
        case .recordingPause: "hotkey.description.recording_pause"
        case .cancel: "hotkey.description.cancel"
        }
    }
}

extension HotkeyType.Category {
    /// ローカライズキー
    var localizedKey: LocalizedStringKey {
        switch self {
        case .recording: "hotkey.category.recording"
        case .cancel: "hotkey.category.cancel"
        }
    }

    /// ローカライズキー（String）
    var localizationKey: String {
        switch self {
        case .recording: "hotkey.category.recording"
        case .cancel: "hotkey.category.cancel"
        }
    }
}

// MARK: - Delegate Action

/// 設定機能のデリゲートアクション
enum SettingsDelegateAction: Sendable, Equatable {
    /// 設定が変更された
    case settingsChanged(AppSettings)
    /// モデルが変更された
    case modelChanged(String)
}
