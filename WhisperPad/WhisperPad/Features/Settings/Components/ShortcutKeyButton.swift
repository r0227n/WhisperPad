//
//  ShortcutKeyButton.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// Shortcut key setting button
///
/// Displays key combination in a dark-styled rounded button.
/// Click to enter edit mode, right-click to show context menu.
struct ShortcutKeyButton: View {
    /// Current key combo
    @Binding var keyCombo: HotKeySettings.KeyComboSettings

    /// Default key combo (for reset)
    let defaultKeyCombo: HotKeySettings.KeyComboSettings

    /// Shortcut type (popupClose allows single keys)
    let hotkeyType: HotkeyType

    /// Whether currently recording
    let isRecording: Bool

    /// Allowed single key keycodes for popupClose
    private static let allowedSingleKeys: Set<UInt16> = [
        53, // Escape
        36, // Return/Enter
        48, // Tab
        51 // Delete/Backspace
    ]

    /// Callback when recording starts
    let onStartRecording: () -> Void

    /// Callback when recording ends
    let onStopRecording: () -> Void

    /// Callback when reset to default
    let onResetToDefault: () -> Void

    /// Event monitor
    @State private var eventMonitor: Any?

    /// Whether mouse has hovered at least once (prevents premature exit on initial state)
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

    /// Recording view
    private var recordingView: some View {
        HStack(spacing: 8) {
            Text(L10n.get(.shortcutEnterKey))
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

            Button(L10n.get(.shortcutCancel)) {
                onStopRecording()
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

    /// Normal display view
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
            Button(L10n.get(.shortcutResetToDefault)) {
                onResetToDefault()
            }
        }
        .accessibilityLabel(L10n.get(.shortcutAccessibilityLabel))
    }

    /// Start key input monitor
    private func startKeyMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // popupClose allows special key alone
            if hotkeyType == .popupClose && Self.allowedSingleKeys.contains(event.keyCode) {
                keyCombo = HotKeySettings.KeyComboSettings(
                    carbonKeyCode: UInt32(event.keyCode),
                    carbonModifiers: 0
                )
                onStopRecording()
                return nil
            }

            // Other types cancel with Escape
            if event.keyCode == 53 {
                onStopRecording()
                return nil
            }

            // Get modifier keys
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Ignore if no modifier keys (require modifier + key combination)
            let hasModifier = modifiers.contains(.command) ||
                modifiers.contains(.option) ||
                modifiers.contains(.control) ||
                modifiers.contains(.shift)

            if !hasModifier {
                return nil
            }

            // Get key code and modifiers and update
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

    /// Remove key input monitor
    private func removeKeyMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
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

        ShortcutKeyButton(
            keyCombo: .constant(.streamingDefault),
            defaultKeyCombo: .streamingDefault,
            hotkeyType: .streaming,
            isRecording: false,
            onStartRecording: {},
            onStopRecording: {},
            onResetToDefault: {}
        )

        ShortcutKeyButton(
            keyCombo: .constant(.popupCloseDefault),
            defaultKeyCombo: .popupCloseDefault,
            hotkeyType: .popupClose,
            isRecording: false,
            onStartRecording: {},
            onStopRecording: {},
            onResetToDefault: {}
        )
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}

#Preview("Recording") {
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
