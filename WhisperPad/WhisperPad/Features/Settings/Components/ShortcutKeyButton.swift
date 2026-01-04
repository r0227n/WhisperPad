//
//  ShortcutKeyButton.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// ショートカットキー設定ボタン
///
/// ダークスタイルの丸角ボタンでキーコンビネーションを表示します。
/// クリックで編集モード、右クリックでコンテキストメニューを表示します。
struct ShortcutKeyButton: View {
    /// 現在のキーコンボ
    @Binding var keyCombo: HotKeySettings.KeyComboSettings

    /// デフォルトのキーコンボ（リセット用）
    let defaultKeyCombo: HotKeySettings.KeyComboSettings

    /// ショートカットタイプ
    let hotkeyType: HotkeyType

    /// 入力中かどうか
    let isRecording: Bool

    /// 許可する単独キーのキーコード
    private static let allowedSingleKeys: Set<UInt16> = [
        53, // Escape
        36, // Return/Enter
        48, // Tab
        51 // Delete/Backspace
    ]

    /// 入力開始時のコールバック
    let onStartRecording: () -> Void

    /// 入力終了時のコールバック
    let onStopRecording: () -> Void

    /// デフォルトにリセット時のコールバック
    let onResetToDefault: () -> Void

    /// イベントモニター
    @State private var eventMonitor: Any?

    /// マウスが一度でもホバーしたか（初期状態での誤終了防止）
    @State private var wasHovered: Bool = false

    var body: some View {
        Group {
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
        HStack(spacing: 16) {
            Text("hotkey.recording.placeholder", comment: "Press key...")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.8), lineWidth: 2)
                )

            Button {
                onStopRecording()
            } label: {
                Text("common.cancel", comment: "Cancel button")
            }
            .buttonStyle(.borderless)
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
        Button {
            onStartRecording()
        } label: {
            Text(keyCombo.displayString)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(NSColor.darkGray))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onResetToDefault()
            } label: {
                Text("hotkey.reset", comment: "Reset to default")
            }
        }
        .accessibilityLabel(
            String(
                localized: "hotkey.accessibility.change",
                defaultValue: "Shortcut: \(keyCombo.displayString). Click to change, right-click for options",
                comment: "Shortcut accessibility label"
            )
        )
    }

    /// キー入力モニターを開始
    private func startKeyMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Escape でキャンセル
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
}

// MARK: - Preview

#Preview("通常状態") {
    VStack(spacing: 20) {
        ShortcutKeyButton(
            keyCombo: .constant(.recordingDefault),
            defaultKeyCombo: .recordingDefault,
            hotkeyType: .recording,
            isRecording: false,
            onStartRecording: {},
            onStopRecording: {},
            onResetToDefault: {}
        )
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}

#Preview("録音中") {
    ShortcutKeyButton(
        keyCombo: .constant(.recordingDefault),
        defaultKeyCombo: .recordingDefault,
        hotkeyType: .recording,
        isRecording: true,
        onStartRecording: {},
        onStopRecording: {},
        onResetToDefault: {}
    )
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}
