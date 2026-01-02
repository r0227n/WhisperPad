//
//  HotkeySettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Shortcut settings tab
///
/// Configures global shortcuts in master-detail format.
/// Left panel: Category-based shortcut list
/// Right panel: Details and editing of selected shortcut
struct HotkeySettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HSplitView {
            // Left panel: Shortcut list
            shortcutListPanel
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)

            // Right panel: Details
            detailPanel
                .frame(minWidth: 280)
        }
        .onAppear {
            // Initial selection
            if store.selectedShortcut == nil {
                store.send(.selectShortcut(.recording))
            }
        }
    }

    // MARK: - Left Panel

    /// Shortcut list panel
    private var shortcutListPanel: some View {
        List(selection: Binding(
            get: { store.selectedShortcut },
            set: { store.send(.selectShortcut($0)) }
        )) {
            ForEach(HotkeyType.Category.allCases) { category in
                Section {
                    ForEach(category.hotkeyTypes) { hotkeyType in
                        ShortcutListRow(
                            hotkeyType: hotkeyType,
                            keyCombo: keyCombo(for: hotkeyType)
                        )
                        .tag(hotkeyType)
                    }
                } header: {
                    Text(category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Right Panel

    /// Detail panel
    @ViewBuilder
    private var detailPanel: some View {
        if let selected = store.selectedShortcut {
            ShortcutDetailPanel(
                hotkeyType: selected,
                keyCombo: keyComboBinding(for: selected),
                menuBarIconSettings: store.settings.general.menuBarIconSettings,
                isRecording: store.recordingHotkeyType == selected,
                onStartRecording: { store.send(.startRecordingHotkey(selected)) },
                onStopRecording: { store.send(.stopRecordingHotkey) },
                onResetToDefault: { resetToDefault(selected) },
                hotkeyConflict: store.hotkeyConflict
            )
        } else {
            placeholderView
        }
    }

    /// Placeholder view
    private var placeholderView: some View {
        VStack {
            Spacer()
            Text(L10n.get(.hotkeySelectShortcut))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    /// Get key combo for the specified shortcut type
    private func keyCombo(for type: HotkeyType) -> HotKeySettings.KeyComboSettings {
        switch type {
        case .recording:
            store.settings.hotKey.recordingHotKey
        case .recordingPause:
            store.settings.hotKey.recordingPauseHotKey
        case .cancel:
            store.settings.hotKey.cancelHotKey
        case .streaming:
            store.settings.hotKey.streamingHotKey
        case .popupCopyAndClose:
            store.settings.hotKey.popupCopyAndCloseHotKey
        case .popupSaveToFile:
            store.settings.hotKey.popupSaveToFileHotKey
        case .popupClose:
            store.settings.hotKey.popupCloseHotKey
        }
    }

    /// Get key combo Binding for the specified shortcut type
    private func keyComboBinding(for type: HotkeyType) -> Binding<HotKeySettings.KeyComboSettings> {
        Binding(
            get: { keyCombo(for: type) },
            set: { newValue in
                var hotKey = store.settings.hotKey
                switch type {
                case .recording:
                    hotKey.recordingHotKey = newValue
                case .recordingPause:
                    hotKey.recordingPauseHotKey = newValue
                case .cancel:
                    hotKey.cancelHotKey = newValue
                case .streaming:
                    hotKey.streamingHotKey = newValue
                case .popupCopyAndClose:
                    hotKey.popupCopyAndCloseHotKey = newValue
                case .popupSaveToFile:
                    hotKey.popupSaveToFileHotKey = newValue
                case .popupClose:
                    hotKey.popupCloseHotKey = newValue
                }
                store.send(.updateHotKeySettings(hotKey))
            }
        )
    }

    /// Reset to default
    private func resetToDefault(_ type: HotkeyType) {
        var hotKey = store.settings.hotKey
        switch type {
        case .recording:
            hotKey.recordingHotKey = .recordingDefault
        case .recordingPause:
            hotKey.recordingPauseHotKey = .recordingPauseDefault
        case .cancel:
            hotKey.cancelHotKey = .cancelDefault
        case .streaming:
            hotKey.streamingHotKey = .streamingDefault
        case .popupCopyAndClose:
            hotKey.popupCopyAndCloseHotKey = .popupCopyAndCloseDefault
        case .popupSaveToFile:
            hotKey.popupSaveToFileHotKey = .popupSaveToFileDefault
        case .popupClose:
            hotKey.popupCloseHotKey = .popupCloseDefault
        }
        store.send(.updateHotKeySettings(hotKey))
    }
}

// MARK: - ShortcutListRow

/// Shortcut list row
private struct ShortcutListRow: View {
    let hotkeyType: HotkeyType
    let keyCombo: HotKeySettings.KeyComboSettings

    var body: some View {
        HStack {
            Text(hotkeyType.displayName)
                .lineLimit(1)

            Spacer()

            // Display key combo in badge style
            Text(keyCombo.displayString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityLabel("\(hotkeyType.displayName), \(L10n.get(.hotkeyShortcutKey)): \(keyCombo.displayString)")
    }
}

// MARK: - ShortcutDetailPanel

/// Shortcut detail panel
private struct ShortcutDetailPanel: View {
    let hotkeyType: HotkeyType
    @Binding var keyCombo: HotKeySettings.KeyComboSettings
    let menuBarIconSettings: MenuBarIconSettings
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onResetToDefault: () -> Void
    let hotkeyConflict: String?

    /// Icon configuration
    private var iconConfig: StatusIconConfig {
        menuBarIconSettings.config(for: hotkeyType.correspondingIconStatus)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header: Icon and title
                headerSection

                Divider()

                // Description section
                descriptionSection

                // Shortcut input section
                shortcutInputSection

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Header section
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: iconConfig.symbolName)
                .font(.title2)
                .foregroundColor(Color(iconConfig.color))
                .frame(width: 32, height: 32)
                .background(Color(iconConfig.color).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(hotkeyType.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(hotkeyType.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Description section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.get(.hotkeyDescription), systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(hotkeyType.hotkeyDescription)
                .foregroundColor(.primary)
        }
    }

    /// Shortcut input section
    private var shortcutInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.get(.hotkeyShortcutKey), systemImage: "keyboard")
                .font(.headline)
                .foregroundColor(.secondary)

            // Key setting button
            ShortcutKeyButton(
                keyCombo: $keyCombo,
                defaultKeyCombo: hotkeyType.defaultKeyCombo,
                hotkeyType: hotkeyType,
                isRecording: isRecording,
                onStartRecording: onStartRecording,
                onStopRecording: onStopRecording,
                onResetToDefault: onResetToDefault
            )

            // Conflict warning
            if let conflict = hotkeyConflict {
                Label(conflict, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .accessibilityLabel("\(L10n.get(.hotkeyShortcutKey)): \(conflict)")
            }

            // Note message
            Text(L10n.get(.hotkeyConflictWarning))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    HotkeySettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 400)
}
