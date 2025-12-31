//
//  HotKeySettings.swift
//  WhisperPad
//

import Foundation

/// ホットキー設定
///
/// グローバルキーボードショートカットの設定を管理します。
struct HotKeySettings: Codable, Equatable, Sendable {
    /// 録音開始/停止のホットキー
    var recordingHotKey: KeyComboSettings

    /// ペーストのホットキー
    var pasteHotKey: KeyComboSettings

    /// 設定を開くホットキー
    var openSettingsHotKey: KeyComboSettings

    /// 録音モード
    var recordingMode: RecordingMode

    /// ストリーミング文字起こしのホットキー
    var streamingHotKey: KeyComboSettings

    /// デフォルト設定
    static let `default` = HotKeySettings()

    /// デフォルト初期化
    init(
        recordingHotKey: KeyComboSettings = .recordingDefault,
        pasteHotKey: KeyComboSettings = .pasteDefault,
        openSettingsHotKey: KeyComboSettings = .openSettingsDefault,
        recordingMode: RecordingMode = .toggle,
        streamingHotKey: KeyComboSettings = .streamingDefault
    ) {
        self.recordingHotKey = recordingHotKey
        self.pasteHotKey = pasteHotKey
        self.openSettingsHotKey = openSettingsHotKey
        self.recordingMode = recordingMode
        self.streamingHotKey = streamingHotKey
    }
}

// MARK: - KeyComboSettings

extension HotKeySettings {
    /// キーコンビネーション設定
    ///
    /// Carbon Event Manager 互換のキーコードと修飾キーを保持します。
    struct KeyComboSettings: Codable, Equatable, Sendable {
        /// Carbon キーコード
        var carbonKeyCode: UInt32

        /// Carbon 修飾キーフラグ
        var carbonModifiers: UInt32

        /// 録音ホットキーのデフォルト（⌥ Space）
        static let recordingDefault = KeyComboSettings(
            carbonKeyCode: 49,
            carbonModifiers: 2048
        )

        /// ペーストホットキーのデフォルト（⌘⇧V）
        static let pasteDefault = KeyComboSettings(
            carbonKeyCode: 9,
            carbonModifiers: 768
        )

        /// 設定を開くホットキーのデフォルト（⌘⇧,）
        static let openSettingsDefault = KeyComboSettings(
            carbonKeyCode: 43,
            carbonModifiers: 768
        )

        /// ストリーミングホットキーのデフォルト（⌘⇧R）
        static let streamingDefault = KeyComboSettings(
            carbonKeyCode: 15,
            carbonModifiers: 768
        )
    }
}

// MARK: - RecordingMode

extension HotKeySettings {
    /// 録音モード
    enum RecordingMode: String, Codable, CaseIterable, Sendable {
        /// トグルモード（1回押しで開始/停止）
        case toggle

        /// プッシュ・トゥ・トーク（押している間のみ録音）
        case pushToTalk

        /// 表示名
        var displayName: String {
            switch self {
            case .toggle:
                "トグル"
            case .pushToTalk:
                "プッシュ・トゥ・トーク"
            }
        }
    }
}
