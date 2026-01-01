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

    /// 設定を開くホットキー
    var openSettingsHotKey: KeyComboSettings

    /// ストリーミング文字起こしのホットキー
    var streamingHotKey: KeyComboSettings

    /// 録音キャンセルのホットキー
    var cancelHotKey: KeyComboSettings

    /// デフォルト設定
    static let `default` = HotKeySettings()

    /// デフォルト初期化
    init(
        recordingHotKey: KeyComboSettings = .recordingDefault,
        openSettingsHotKey: KeyComboSettings = .openSettingsDefault,
        streamingHotKey: KeyComboSettings = .streamingDefault,
        cancelHotKey: KeyComboSettings = .cancelDefault
    ) {
        self.recordingHotKey = recordingHotKey
        self.openSettingsHotKey = openSettingsHotKey
        self.streamingHotKey = streamingHotKey
        self.cancelHotKey = cancelHotKey
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
    }
}
