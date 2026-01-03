//
//  HotkeyRecorderView.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// ホットキー入力コンポーネント
///
/// ユーザーがキーコンビネーションを設定するためのビューです。
/// クリックして入力モードに入り、キーを押すと設定されます。
/// NSEvent.addLocalMonitorForEvents を使用してキー入力をキャプチャします。
struct HotkeyRecorderView: View {
    /// ラベル
    let label: String

    /// 現在のキーコンボ
    @Binding var keyCombo: HotKeySettings.KeyComboSettings

    /// 入力中かどうか
    let isRecording: Bool

    /// 入力開始時のコールバック
    let onStartRecording: () -> Void

    /// 入力終了時のコールバック
    let onStopRecording: () -> Void

    /// クリア時のコールバック
    let onClear: () -> Void

    /// イベントモニター
    @State private var eventMonitor: Any?

    /// マウスが一度でもホバーしたか（初期状態での誤終了防止）
    @State private var wasHovered: Bool = false

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            if isRecording {
                recordingView
            } else {
                displayView
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                wasHovered = false
                startKeyMonitor()
            } else {
                removeKeyMonitor()
            }
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    /// 録音中の表示
    private var recordingView: some View {
        HStack(spacing: 8) {
            Text("hotkey.input.waiting", comment: "Placeholder shown while waiting for hotkey input")
                .foregroundColor(.secondary)
                .frame(minWidth: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.3))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .accessibilityLabel(String(localized: "hotkey.input.recording", comment: "Recording key"))

            Button("common.cancel", comment: "Cancel button") {
                onStopRecording()
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "common.cancel", comment: "Cancel"))
            .accessibilityHint(String(localized: "hotkey.input.cancel", comment: "Cancel hotkey input"))
        }
        .onHover { hovering in
            if hovering {
                wasHovered = true
            } else if wasHovered {
                onStopRecording()
            }
        }
    }

    /// 通常の表示
    private var displayView: some View {
        HStack(spacing: 8) {
            Button {
                onStartRecording()
            } label: {
                Text(displayString(keyCombo))
                    .frame(minWidth: 80)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    localized: "hotkey.display.label",
                    defaultValue: "\(label) hotkey: \(displayString(keyCombo)). Click to change",
                    comment: "Hotkey display accessibility label"
                )
            )

            Button("common.clear", comment: "Clear button") {
                onClear()
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "common.clear", comment: "Clear"))
            .accessibilityHint(String(localized: "hotkey.input.clear", comment: "Reset hotkey to default"))
        }
    }

    /// キー入力モニターを開始
    private func startKeyMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Escape キーでキャンセル
            if event.keyCode == 53 {
                onStopRecording()
                return nil
            }

            // 修飾キーを取得
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // 修飾キーがない場合は無視（修飾キー + キーの組み合わせを必須とする）
            let hasModifier = modifiers.contains(.command) ||
                modifiers.contains(.option) ||
                modifiers.contains(.control) ||
                modifiers.contains(.shift)

            if !hasModifier {
                return nil
            }

            // キーコードと修飾キーを取得して更新
            let carbonKeyCode = UInt32(event.keyCode)
            let carbonModifiers = modifiers.carbonFlags

            keyCombo = HotKeySettings.KeyComboSettings(
                carbonKeyCode: carbonKeyCode,
                carbonModifiers: carbonModifiers
            )

            onStopRecording()
            return nil
        }
    }

    /// キー入力モニターを削除
    private func removeKeyMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// キーコンボを表示用文字列に変換
    private func displayString(_ combo: HotKeySettings.KeyComboSettings) -> String {
        var symbols: [String] = []

        // 修飾キー (Carbon flags)
        let mods = combo.carbonModifiers
        if mods & 4096 != 0 { symbols.append("⌃") } // Control
        if mods & 2048 != 0 { symbols.append("⌥") } // Option
        if mods & 512 != 0 { symbols.append("⇧") } // Shift
        if mods & 256 != 0 { symbols.append("⌘") } // Command

        // キー名
        symbols.append(keyName(combo.carbonKeyCode))

        return symbols.joined()
    }

    /// Carbon キーコードを表示名に変換
    private func keyName(_ keyCode: UInt32) -> String {
        KeyCodeMapper.keyName(for: keyCode)
    }
}

// MARK: - KeyCodeMapper

/// Carbon キーコードを表示名にマップするユーティリティ
private enum KeyCodeMapper {
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

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags {
    /// Carbon 修飾キーフラグに変換
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= 256 } // cmdKey
        if contains(.shift) { flags |= 512 } // shiftKey
        if contains(.option) { flags |= 2048 } // optionKey
        if contains(.control) { flags |= 4096 } // controlKey
        return flags
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HotkeyRecorderView(
            label: "録音開始/停止",
            keyCombo: .constant(.recordingDefault),
            isRecording: false,
            onStartRecording: {},
            onStopRecording: {},
            onClear: {}
        )

        HotkeyRecorderView(
            label: "録音開始/停止",
            keyCombo: .constant(.recordingDefault),
            isRecording: true,
            onStartRecording: {},
            onStopRecording: {},
            onClear: {}
        )
    }
    .padding()
    .frame(width: 400)
}
