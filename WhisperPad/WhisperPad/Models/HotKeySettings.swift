//
//  HotKeySettings.swift
//  WhisperPad
//

import AppKit
import Foundation

/// ホットキー設定
///
/// グローバルキーボードショートカットの設定を管理します。
struct HotKeySettings: Codable, Equatable, Sendable {
    /// 録音開始/停止のホットキー
    var recordingHotKey: KeyComboSettings

    /// 録音キャンセルのホットキー
    var cancelHotKey: KeyComboSettings

    /// 録音一時停止のホットキー
    var recordingPauseHotKey: KeyComboSettings

    /// デフォルト設定
    static let `default` = HotKeySettings()

    /// デフォルト初期化
    init(
        recordingHotKey: KeyComboSettings = .recordingDefault,
        cancelHotKey: KeyComboSettings = .cancelDefault,
        recordingPauseHotKey: KeyComboSettings = .recordingPauseDefault
    ) {
        self.recordingHotKey = recordingHotKey
        self.cancelHotKey = cancelHotKey
        self.recordingPauseHotKey = recordingPauseHotKey
    }

    // MARK: - Codable (Migration Support)

    private enum CodingKeys: String, CodingKey {
        case recordingHotKey
        case cancelHotKey, recordingPauseHotKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        recordingHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingHotKey)
            ?? .recordingDefault
        cancelHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .cancelHotKey)
            ?? .cancelDefault
        recordingPauseHotKey = try container.decodeIfPresent(KeyComboSettings.self, forKey: .recordingPauseHotKey)
            ?? .recordingPauseDefault
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordingHotKey, forKey: .recordingHotKey)
        try container.encode(cancelHotKey, forKey: .cancelHotKey)
        try container.encode(recordingPauseHotKey, forKey: .recordingPauseHotKey)
    }

    // MARK: - Update Helper

    /// 指定されたホットキータイプのキーコンボを更新
    ///
    /// - Parameters:
    ///   - type: 更新するホットキータイプ
    ///   - combo: 新しいキーコンボ設定
    mutating func update(for type: HotkeyType, combo: KeyComboSettings) {
        switch type {
        case .recording:
            recordingHotKey = combo
        case .cancel:
            cancelHotKey = combo
        case .recordingPause:
            recordingPauseHotKey = combo
        }
    }

    /// 指定されたホットキータイプのキーコンボを取得
    ///
    /// - Parameter type: 取得するホットキータイプ
    /// - Returns: キーコンボ設定
    func keyCombo(for type: HotkeyType) -> KeyComboSettings {
        switch type {
        case .recording:
            recordingHotKey
        case .cancel:
            cancelHotKey
        case .recordingPause:
            recordingPauseHotKey
        }
    }

    // MARK: - Conflict Detection

    /// ホットキー間の内部コンフリクトを検出
    ///
    /// 同じキーコンボが複数のホットキーに割り当てられている場合、
    /// コンフリクトしているホットキータイプのペアを返します。
    ///
    /// - Returns: コンフリクトしているホットキータイプのペア配列
    func findInternalConflicts() -> [(HotkeyType, HotkeyType)] {
        let types = HotkeyType.allCases
        var conflicts: [(HotkeyType, HotkeyType)] = []

        for index in 0 ..< types.count {
            for otherIndex in (index + 1) ..< types.count {
                let type1 = types[index]
                let type2 = types[otherIndex]
                let combo1 = keyCombo(for: type1)
                let combo2 = keyCombo(for: type2)

                if combo1.carbonKeyCode == combo2.carbonKeyCode,
                   combo1.carbonModifiers == combo2.carbonModifiers {
                    conflicts.append((type1, type2))
                }
            }
        }

        return conflicts
    }

    /// 指定されたキーコンボが他のホットキーと重複しているかチェック
    ///
    /// - Parameters:
    ///   - targetType: チェック対象のホットキータイプ
    ///   - combo: チェックするキーコンボ
    /// - Returns: 重複しているホットキータイプ（重複なしの場合は nil）
    func findDuplicateHotkey(
        for targetType: HotkeyType,
        with combo: KeyComboSettings
    ) -> HotkeyType? {
        for type in HotkeyType.allCases where type != targetType {
            let existingCombo = keyCombo(for: type)
            // デフォルト設定との重複は許可
            if existingCombo == type.defaultKeyCombo, combo == targetType.defaultKeyCombo {
                continue
            }
            if existingCombo.carbonKeyCode == combo.carbonKeyCode,
               existingCombo.carbonModifiers == combo.carbonModifiers {
                return type
            }
        }
        return nil
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

        /// 録音ホットキーのデフォルト（⌘⌥R）
        static let recordingDefault = KeyComboSettings(
            carbonKeyCode: 15,
            carbonModifiers: 2304
        )

        /// キャンセルホットキーのデフォルト（⌘⌥.）
        static let cancelDefault = KeyComboSettings(
            carbonKeyCode: 47,
            carbonModifiers: 2304
        )

        /// 録音一時停止ホットキーのデフォルト（⌘⌥P）
        static let recordingPauseDefault = KeyComboSettings(
            carbonKeyCode: 35,
            carbonModifiers: 2304
        )
    }
}

// MARK: - KeyComboSettings Display

extension HotKeySettings.KeyComboSettings {
    /// ショートカットを表示用文字列に変換（例: "⌥⇧S"）
    var displayString: String {
        var symbols: [String] = []

        // 修飾キー (Carbon flags)
        if carbonModifiers & 4096 != 0 { symbols.append("⌃") } // Control
        if carbonModifiers & 2048 != 0 { symbols.append("⌥") } // Option
        if carbonModifiers & 512 != 0 { symbols.append("⇧") } // Shift
        if carbonModifiers & 256 != 0 { symbols.append("⌘") } // Command

        // キー名
        symbols.append(keyName)

        return symbols.joined()
    }

    /// Carbon キーコードを表示名に変換
    private var keyName: String {
        let keyNames: [UInt32: String] = [
            // アルファベットキー
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            // 数字キー
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7",
            27: "-", 28: "8", 29: "0",
            // 記号キー
            30: "]", 33: "[", 39: "'", 41: ";", 42: "\\", 43: ",", 44: "/", 47: ".", 50: "`",
            // 特殊キー
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            // 矢印キー
            123: "←", 124: "→", 125: "↓", 126: "↑",
            // ファンクションキー
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
            118: "F4", 120: "F2", 122: "F1",
            // その他
            119: "End", 121: "PgDn"
        ]
        return keyNames[carbonKeyCode] ?? "Key\(carbonKeyCode)"
    }
}

// MARK: - KeyComboSettings NSMenuItem Support

extension HotKeySettings.KeyComboSettings {
    /// NSMenuItem.keyEquivalent 用の文字列
    var keyEquivalentCharacter: String {
        let keyChars: [UInt32: String] = [
            // アルファベットキー（小文字）
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t",
            31: "o", 32: "u", 34: "i", 35: "p", 37: "l", 38: "j", 40: "k", 45: "n", 46: "m",
            // 数字キー
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7",
            27: "-", 28: "8", 29: "0",
            // 記号キー
            30: "]", 33: "[", 39: "'", 41: ";", 42: "\\", 43: ",", 44: "/", 47: ".", 50: "`",
            // 特殊キー
            36: "\r", 48: "\t", 49: " ", 51: "\u{08}", 53: "\u{1B}",
            // 矢印キー
            123: "\u{F702}", 124: "\u{F703}", 125: "\u{F701}", 126: "\u{F700}"
        ]
        return keyChars[carbonKeyCode] ?? ""
    }

    /// NSMenuItem.keyEquivalentModifierMask 用のフラグ
    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & 4096 != 0 { flags.insert(.control) }
        if carbonModifiers & 2048 != 0 { flags.insert(.option) }
        if carbonModifiers & 512 != 0 { flags.insert(.shift) }
        if carbonModifiers & 256 != 0 { flags.insert(.command) }
        return flags
    }
}
