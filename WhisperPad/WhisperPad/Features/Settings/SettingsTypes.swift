//
//  SettingsTypes.swift
//  WhisperPad
//

import Foundation

// MARK: - Settings Tab

/// 設定タブ
enum SettingsTab: String, CaseIterable, Sendable {
    case general = "一般"
    case icon = "アイコン"
    case hotkey = "ホットキー"
    case recording = "録音"
    case model = "モデル"
    case output = "出力"

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
        case .output:
            "doc.on.clipboard"
        }
    }
}

// MARK: - Hotkey Type

/// ホットキータイプ（どのホットキーを編集中か）
enum HotkeyType: String, CaseIterable, Sendable {
    case recording
    case openSettings
    case streaming
    case cancel
    case recordingToggle
    case recordingPause
}

// MARK: - Delegate Action

/// 設定機能のデリゲートアクション
enum SettingsDelegateAction: Sendable, Equatable {
    /// 設定が変更された
    case settingsChanged(AppSettings)
    /// モデルが変更された
    case modelChanged(String)
}
