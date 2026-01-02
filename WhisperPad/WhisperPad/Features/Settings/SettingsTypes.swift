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
    case streaming
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
                [.recording, .recordingPause, .streaming]
            case .cancel:
                [.cancel]
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
        case .streaming:
            "ストリーミング"
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
        case .streaming:
            "リアルタイム文字起こしを開始します"
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
