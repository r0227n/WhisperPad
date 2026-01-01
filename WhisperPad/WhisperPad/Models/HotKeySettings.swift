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

    /// 録音キャンセルのホットキー
    var cancelHotKey: KeyComboSettings

    /// 録音開始/終了のトグルホットキー
    var recordingToggleHotKey: KeyComboSettings

    /// 録音一時停止のホットキー
    var recordingPauseHotKey: KeyComboSettings

    /// デフォルト設定
    static let `default` = HotKeySettings()

    /// デフォルト初期化
    init(
        recordingHotKey: KeyComboSettings = .recordingDefault,
        pasteHotKey: KeyComboSettings = .pasteDefault,
        openSettingsHotKey: KeyComboSettings = .openSettingsDefault,
        recordingMode: RecordingMode = .toggle,
        streamingHotKey: KeyComboSettings = .streamingDefault,
        cancelHotKey: KeyComboSettings = .cancelDefault,
        recordingToggleHotKey: KeyComboSettings = .recordingToggleDefault,
        recordingPauseHotKey: KeyComboSettings = .recordingPauseDefault
    ) {
        self.recordingHotKey = recordingHotKey
        self.pasteHotKey = pasteHotKey
        self.openSettingsHotKey = openSettingsHotKey
        self.recordingMode = recordingMode
        self.streamingHotKey = streamingHotKey
        self.cancelHotKey = cancelHotKey
        self.recordingToggleHotKey = recordingToggleHotKey
        self.recordingPauseHotKey = recordingPauseHotKey
    }

    // MARK: - Codable (Migration Support)

    private enum CodingKeys: String, CodingKey {
        case recordingHotKey, pasteHotKey, openSettingsHotKey, recordingMode
        case streamingHotKey, cancelHotKey, recordingPauseHotKey
        case recordingToggleHotKey
        // Legacy keys for migration
        case recordingStartHotKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        recordingHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingHotKey)
            ?? .recordingDefault
        pasteHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .pasteHotKey)
            ?? .pasteDefault
        openSettingsHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .openSettingsHotKey)
            ?? .openSettingsDefault
        recordingMode = try container.decodeIfPresent(RecordingMode.self, forKey: .recordingMode)
            ?? .toggle
        streamingHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .streamingHotKey)
            ?? .streamingDefault
        cancelHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .cancelHotKey)
            ?? .cancelDefault
        recordingPauseHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingPauseHotKey)
            ?? .recordingPauseDefault

        // Migration: try recordingToggleHotKey first, fall back to recordingStartHotKey
        if let toggleKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingToggleHotKey) {
            recordingToggleHotKey = toggleKey
        } else if let startKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingStartHotKey) {
            recordingToggleHotKey = startKey
        } else {
            recordingToggleHotKey = .recordingToggleDefault
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordingHotKey, forKey: .recordingHotKey)
        try container.encode(pasteHotKey, forKey: .pasteHotKey)
        try container.encode(openSettingsHotKey, forKey: .openSettingsHotKey)
        try container.encode(recordingMode, forKey: .recordingMode)
        try container.encode(streamingHotKey, forKey: .streamingHotKey)
        try container.encode(cancelHotKey, forKey: .cancelHotKey)
        try container.encode(recordingToggleHotKey, forKey: .recordingToggleHotKey)
        try container.encode(recordingPauseHotKey, forKey: .recordingPauseHotKey)
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

        /// キャンセルホットキーのデフォルト（Escape）
        static let cancelDefault = KeyComboSettings(
            carbonKeyCode: 53,
            carbonModifiers: 0
        )

        /// 録音開始/終了トグルホットキーのデフォルト（⌥⇧S）
        static let recordingToggleDefault = KeyComboSettings(
            carbonKeyCode: 1,
            carbonModifiers: 2560
        )

        /// 録音一時停止ホットキーのデフォルト（⌥⇧P）
        static let recordingPauseDefault = KeyComboSettings(
            carbonKeyCode: 35,
            carbonModifiers: 2560
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
