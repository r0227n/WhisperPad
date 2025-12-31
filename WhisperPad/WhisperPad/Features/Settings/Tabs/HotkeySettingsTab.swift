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
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 36: return "↩"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 43: return ","
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "⎋"
        default:
            if keyCode <= 25 {
                return String(Character(UnicodeScalar(65 + Int(keyCode))!))
            }
            return "Key\(keyCode)"
        }
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
