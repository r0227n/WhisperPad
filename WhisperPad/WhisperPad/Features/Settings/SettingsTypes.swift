//
//  SettingsTypes.swift
//  WhisperPad
//

import Foundation

// MARK: - Settings Tab

/// Settings tab
enum SettingsTab: String, CaseIterable, Sendable {
    case general
    case icon
    case hotkey
    case recording
    case model

    /// SF Symbol name
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

    /// Localized display name
    @MainActor
    var displayName: String {
        switch self {
        case .general:
            L10n.get(.settingsTabGeneral)
        case .icon:
            L10n.get(.settingsTabIcon)
        case .hotkey:
            L10n.get(.settingsTabHotkey)
        case .recording:
            L10n.get(.settingsTabRecording)
        case .model:
            L10n.get(.settingsTabModel)
        }
    }
}

// MARK: - Hotkey Type

/// Shortcut type (which shortcut is being edited)
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
    /// Shortcut category
    enum Category: String, CaseIterable, Identifiable {
        case recording
        case cancel
        case popup

        var id: String { rawValue }

        /// Localized display name
        @MainActor
        var displayName: String {
            switch self {
            case .recording:
                L10n.get(.hotkeyCategoryRecording)
            case .cancel:
                L10n.get(.hotkeyCategoryCancel)
            case .popup:
                L10n.get(.hotkeyCategoryPopup)
            }
        }

        /// Hotkey types belonging to this category
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

    /// Shortcut category
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

    /// Localized display name
    @MainActor
    var displayName: String {
        switch self {
        case .recording:
            L10n.get(.hotkeyTypeRecording)
        case .recordingPause:
            L10n.get(.hotkeyTypePause)
        case .cancel:
            L10n.get(.hotkeyTypeCancel)
        case .streaming:
            L10n.get(.hotkeyTypeStreaming)
        case .popupCopyAndClose:
            L10n.get(.hotkeyTypeCopyAndClose)
        case .popupSaveToFile:
            L10n.get(.hotkeyTypeSaveToFile)
        case .popupClose:
            L10n.get(.hotkeyTypeClose)
        }
    }

    /// Localized description
    @MainActor
    var hotkeyDescription: String {
        switch self {
        case .recording:
            L10n.get(.hotkeyTypeRecordingDescription)
        case .recordingPause:
            L10n.get(.hotkeyTypePauseDescription)
        case .cancel:
            L10n.get(.hotkeyTypeCancelDescription)
        case .streaming:
            L10n.get(.hotkeyTypeStreamingDescription)
        case .popupCopyAndClose:
            L10n.get(.hotkeyTypeCopyAndCloseDescription)
        case .popupSaveToFile:
            L10n.get(.hotkeyTypeSaveToFileDescription)
        case .popupClose:
            L10n.get(.hotkeyTypeCloseDescription)
        }
    }

    /// Default key combo
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

    /// SF Symbol icon name
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

    /// Corresponding icon status
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

// MARK: - Delegate Action

/// Settings feature delegate action
enum SettingsDelegateAction: Sendable, Equatable {
    /// Settings changed
    case settingsChanged(AppSettings)
    /// Model changed
    case modelChanged(String)
}
