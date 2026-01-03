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
    case hotkey = "ショートカット"
    case recording = "録音"
    case model = "モデル"

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
    case cancel
    case recordingPause

    var id: String { rawValue }
}

// MARK: - HotkeyType Metadata

extension HotkeyType {
    /// ショートカットのカテゴリ
    enum Category: String, CaseIterable, Identifiable {
        case recording = "録音"
        case cancel = "キャンセル"

        var id: String { rawValue }

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

    /// 表示名
    var displayName: String {
        switch self {
        case .recording:
            "録音開始/停止"
        case .recordingPause:
            "一時停止/再開"
        case .cancel:
            "録音キャンセル"
        }
    }

    /// 説明
    var hotkeyDescription: String {
        switch self {
        case .recording:
            "録音を開始または停止します"
        case .recordingPause:
            "録音を一時停止または再開します"
        case .cancel:
            "進行中の録音をキャンセルします"
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

// MARK: - Delegate Action

/// 設定機能のデリゲートアクション
enum SettingsDelegateAction: Sendable, Equatable {
    /// 設定が変更された
    case settingsChanged(AppSettings)
    /// モデルが変更された
    case modelChanged(String)
}
