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
            Text("キーを入力...")
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

            Button("キャンセル") {
                onStopRecording()
            }
            .buttonStyle(.borderless)
        }
    }

    /// 通常の表示
    private var displayView: some View {
        HStack(spacing: 8) {
            Text(displayString(keyCombo))
                .frame(minWidth: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

            Button("変更") {
                onStartRecording()
            }
            .buttonStyle(.borderless)

            Button("クリア") {
                onClear()
            }
            .buttonStyle(.borderless)
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
        switch keyCode {
        case 0: "A"
        case 1: "S"
        case 2: "D"
        case 3: "F"
        case 4: "H"
        case 5: "G"
        case 6: "Z"
        case 7: "X"
        case 8: "C"
        case 9: "V"
        case 11: "B"
        case 12: "Q"
        case 13: "W"
        case 14: "E"
        case 15: "R"
        case 16: "Y"
        case 17: "T"
        case 18: "1"
        case 19: "2"
        case 20: "3"
        case 21: "4"
        case 22: "6"
        case 23: "5"
        case 24: "="
        case 25: "9"
        case 26: "7"
        case 27: "-"
        case 28: "8"
        case 29: "0"
        case 30: "]"
        case 31: "O"
        case 32: "U"
        case 33: "["
        case 34: "I"
        case 35: "P"
        case 36: "↩"
        case 37: "L"
        case 38: "J"
        case 39: "'"
        case 40: "K"
        case 41: ";"
        case 42: "\\"
        case 43: ","
        case 44: "/"
        case 45: "N"
        case 46: "M"
        case 47: "."
        case 48: "⇥"
        case 49: "Space"
        case 50: "`"
        case 51: "⌫"
        case 53: "⎋"
        case 96: "F5"
        case 97: "F6"
        case 98: "F7"
        case 99: "F3"
        case 100: "F8"
        case 101: "F9"
        case 103: "F11"
        case 105: "F13"
        case 107: "F14"
        case 109: "F10"
        case 111: "F12"
        case 113: "F15"
        case 118: "F4"
        case 119: "End"
        case 120: "F2"
        case 121: "PgDn"
        case 122: "F1"
        case 123: "←"
        case 124: "→"
        case 125: "↓"
        case 126: "↑"
        default: "Key\(keyCode)"
        }
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
