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
}

// MARK: - Hotkey Type

/// ショートカットタイプ（どのショートカットを編集中か）
enum HotkeyType: String, CaseIterable, Sendable, Identifiable {
    case recording
    case streaming
    case cancel
    case recordingPause
    case popupCopyAndClose
    case popupSaveToFile
    case popupClose

    var id: String { rawValue }
}

// MARK: - HotkeyType Metadata

extension HotkeyType {
    /// ショートカットのカテゴリ
    enum Category: String, CaseIterable, Identifiable {
        case recording
        case cancel
        case popup

        var id: String { rawValue }

        /// 表示名（ローカライズ済み）
        var displayName: String {
            switch self {
            case .recording:
                String(localized: "hotkey.category.recording", comment: "Recording")
            case .cancel:
                String(localized: "hotkey.category.cancel", comment: "Cancel")
            case .popup:
                String(localized: "hotkey.category.popup", comment: "Popup")
            }
        }

        /// このカテゴリに属するショートカットタイプ
        var hotkeyTypes: [HotkeyType] {
            switch self {
            case .recording:
                [.recording, .recordingPause, .streaming]
            case .cancel:
                [.cancel]
            case .popup:
                [.popupCopyAndClose, .popupSaveToFile, .popupClose]
            }
        }
    }

    /// ショートカットのカテゴリ
    var category: Category {
        switch self {
        case .recording, .recordingPause, .streaming:
            .recording
        case .cancel:
            .cancel
        case .popupCopyAndClose, .popupSaveToFile, .popupClose:
            .popup
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
        case .streaming:
            String(localized: "hotkey.type.streaming", comment: "Streaming")
        case .popupCopyAndClose:
            String(localized: "hotkey.type.copy_and_close", comment: "Copy and Close")
        case .popupSaveToFile:
            String(localized: "hotkey.type.save_to_file", comment: "Save to File")
        case .popupClose:
            String(localized: "hotkey.type.close", comment: "Close")
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
        case .streaming:
            String(localized: "hotkey.description.streaming", comment: "Start real-time transcription")
        case .popupCopyAndClose:
            String(localized: "hotkey.description.copy_and_close", comment: "Copy to clipboard and close popup")
        case .popupSaveToFile:
            String(localized: "hotkey.description.save_to_file", comment: "Save transcription to file")
        case .popupClose:
            String(localized: "hotkey.description.close", comment: "Close popup")
        }
    }

    /// デフォルトのキーコンボ
    var defaultKeyCombo: HotKeySettings.KeyComboSettings {
        switch self {
        case .recording:
            .recordingDefault
        case .recordingPause:
            .recordingPauseDefault
        case .cancel:
            .cancelDefault
        case .streaming:
            .streamingDefault
        case .popupCopyAndClose:
            .popupCopyAndCloseDefault
        case .popupSaveToFile:
            .popupSaveToFileDefault
        case .popupClose:
            .popupCloseDefault
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
        case .streaming:
            "waveform"
        case .popupCopyAndClose:
            "doc.on.clipboard"
        case .popupSaveToFile:
            "square.and.arrow.down"
        case .popupClose:
            "xmark"
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
        case .streaming:
            .streamingTranscribing
        case .popupCopyAndClose:
            .streamingCompleted
        case .popupSaveToFile:
            .streamingCompleted
        case .popupClose:
            .streamingTranscribing
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
        case .streaming: "hotkey.type.streaming"
        case .popupCopyAndClose: "hotkey.type.copy_and_close"
        case .popupSaveToFile: "hotkey.type.save_to_file"
        case .popupClose: "hotkey.type.close"
        }
    }

    /// 説明のローカライズキー
    var descriptionKey: LocalizedStringKey {
        switch self {
        case .recording: "hotkey.description.recording"
        case .recordingPause: "hotkey.description.recording_pause"
        case .cancel: "hotkey.description.cancel"
        case .streaming: "hotkey.description.streaming"
        case .popupCopyAndClose: "hotkey.description.copy_and_close"
        case .popupSaveToFile: "hotkey.description.save_to_file"
        case .popupClose: "hotkey.description.close"
        }
    }
}

extension HotkeyType.Category {
    /// ローカライズキー
    var localizedKey: LocalizedStringKey {
        switch self {
        case .recording: "hotkey.category.recording"
        case .cancel: "hotkey.category.cancel"
        case .popup: "hotkey.category.popup"
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
