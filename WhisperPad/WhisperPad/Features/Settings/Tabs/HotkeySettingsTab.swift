//
//  HotkeySettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ホットキー設定タブ
///
/// グローバルホットキーの設定を行います。
/// 録音、ペースト、設定を開くホットキーを変更できます。
struct HotkeySettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // 録音セクション
            Section {
                HStack {
                    Text("録音開始/停止")
                    Spacer()
                    Text(displayKeyCombo(store.settings.hotKey.recordingHotKey))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .help("録音を開始または停止するホットキー")

                Picker(
                    "録音モード",
                    selection: Binding(
                        get: { store.settings.hotKey.recordingMode },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.recordingMode = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    )
                ) {
                    ForEach(HotKeySettings.RecordingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("トグル: 1回押しで開始/停止、プッシュ・トゥ・トーク: 押している間のみ録音")
            } header: {
                Text("録音")
            }

            // 出力セクション
            Section {
                HStack {
                    Text("最後の書き起こしをペースト")
                    Spacer()
                    Text(displayKeyCombo(store.settings.hotKey.pasteHotKey))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .help("最後に文字起こしした内容をペーストするホットキー")
            } header: {
                Text("出力")
            }

            // アプリセクション
            Section {
                HStack {
                    Text("設定を開く")
                    Spacer()
                    Text(displayKeyCombo(store.settings.hotKey.openSettingsHotKey))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .help("設定画面を開くホットキー")
            } header: {
                Text("アプリ")
            }

            // 注意セクション
            Section {
                Label(
                    "他のアプリと競合する場合は変更してください",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundColor(.secondary)
                .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    /// キーコンボを表示用文字列に変換
    private func displayKeyCombo(_ combo: HotKeySettings.KeyComboSettings) -> String {
        var symbols: [String] = []

        let mods = combo.carbonModifiers
        if mods & 4096 != 0 { symbols.append("⌃") } // Control
        if mods & 2048 != 0 { symbols.append("⌥") } // Option
        if mods & 512 != 0 { symbols.append("⇧") } // Shift
        if mods & 256 != 0 { symbols.append("⌘") } // Command

        symbols.append(keyName(combo.carbonKeyCode))

        return symbols.joined()
    }

    /// Carbon キーコードを表示名に変換
    private func keyName(_ keyCode: UInt32) -> String {
        HotkeyKeyCodeMapper.keyName(for: keyCode)
    }
}

// MARK: - KeyCodeMapper

/// Carbon キーコードを表示名にマップするユーティリティ
private enum HotkeyKeyCodeMapper {
    /// キーコードから表示名へのマッピング
    static let keyNames: [UInt32: String] = [
        // アルファベットキー
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
        // 数字キー
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        // 記号キー
        30: "]", 33: "[", 39: "'", 41: ";", 42: "\\", 43: ",", 44: "/", 47: ".", 50: "`",
        // 特殊キー
        36: "\u{21A9}", // ↩
        48: "\u{21E5}", // ⇥
        49: "Space",
        51: "\u{232B}", // ⌫
        53: "\u{238B}", // ⎋
        // 矢印キー
        123: "\u{2190}", // ←
        124: "\u{2192}", // →
        125: "\u{2193}", // ↓
        126: "\u{2191}", // ↑
        // ファンクションキー
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
        118: "F4", 120: "F2", 122: "F1",
        // その他
        119: "End", 121: "PgDn"
    ]

    /// キーコードから表示名を取得
    static func keyName(for keyCode: UInt32) -> String {
        keyNames[keyCode] ?? "Key\(keyCode)"
    }
}

// MARK: - Preview

#Preview {
    HotkeySettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 500, height: 400)
}
