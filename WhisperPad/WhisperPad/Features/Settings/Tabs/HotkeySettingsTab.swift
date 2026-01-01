//
//  HotkeySettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ホットキー設定タブ
///
/// マスター・ディテール形式でグローバルホットキーの設定を行います。
/// 左パネル：カテゴリ別ショートカット一覧
/// 右パネル：選択したショートカットの詳細と編集
struct HotkeySettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        HSplitView {
            // 左パネル: ショートカット一覧
            shortcutListPanel
                .frame(minWidth: 200, idealWidth: 220)

            // 右パネル: 詳細
            detailPanel
                .frame(minWidth: 250)
        }
        .onAppear {
            // 初期選択
            if store.selectedShortcut == nil {
                store.send(.selectShortcut(.recording))
            }
        }
    }

    // MARK: - Left Panel

    /// ショートカット一覧パネル
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
                    Text(category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Right Panel

    /// 詳細パネル
    @ViewBuilder
    private var detailPanel: some View {
        if let selected = store.selectedShortcut {
            ShortcutDetailPanel(
                hotkeyType: selected,
                keyCombo: keyComboBinding(for: selected),
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

    /// プレースホルダービュー
    private var placeholderView: some View {
        VStack {
            Spacer()
            Text("ショートカットを選択してください")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    /// 指定されたホットキータイプのキーコンボを取得
    private func keyCombo(for type: HotkeyType) -> HotKeySettings.KeyComboSettings {
        switch type {
        case .recording:
            store.settings.hotKey.recordingHotKey
        case .recordingToggle:
            store.settings.hotKey.recordingToggleHotKey
        case .recordingPause:
            store.settings.hotKey.recordingPauseHotKey
        case .cancel:
            store.settings.hotKey.cancelHotKey
        case .streaming:
            store.settings.hotKey.streamingHotKey
        }
    }

    /// 指定されたホットキータイプのキーコンボBindingを取得
    private func keyComboBinding(for type: HotkeyType) -> Binding<HotKeySettings.KeyComboSettings> {
        Binding(
            get: { keyCombo(for: type) },
            set: { newValue in
                var hotKey = store.settings.hotKey
                switch type {
                case .recording:
                    hotKey.recordingHotKey = newValue
                case .recordingToggle:
                    hotKey.recordingToggleHotKey = newValue
                case .recordingPause:
                    hotKey.recordingPauseHotKey = newValue
                case .cancel:
                    hotKey.cancelHotKey = newValue
                case .streaming:
                    hotKey.streamingHotKey = newValue
                }
                store.send(.updateHotKeySettings(hotKey))
            }
        )
    }

    /// デフォルトにリセット
    private func resetToDefault(_ type: HotkeyType) {
        var hotKey = store.settings.hotKey
        switch type {
        case .recording:
            hotKey.recordingHotKey = .recordingDefault
        case .recordingToggle:
            hotKey.recordingToggleHotKey = .recordingToggleDefault
        case .recordingPause:
            hotKey.recordingPauseHotKey = .recordingPauseDefault
        case .cancel:
            hotKey.cancelHotKey = .cancelDefault
        case .streaming:
            hotKey.streamingHotKey = .streamingDefault
        }
        store.send(.updateHotKeySettings(hotKey))
    }
}

// MARK: - ShortcutListRow

/// ショートカット一覧の行
private struct ShortcutListRow: View {
    let hotkeyType: HotkeyType
    let keyCombo: HotKeySettings.KeyComboSettings

    var body: some View {
        HStack {
            Text(hotkeyType.displayName)
                .lineLimit(1)

            Spacer()

            Text(keyCombo.displayString)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityLabel("\(hotkeyType.displayName)、ショートカット: \(keyCombo.displayString)")
    }
}

// MARK: - ShortcutDetailPanel

/// ショートカット詳細パネル
private struct ShortcutDetailPanel: View {
    let hotkeyType: HotkeyType
    @Binding var keyCombo: HotKeySettings.KeyComboSettings
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onResetToDefault: () -> Void
    let hotkeyConflict: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            Text(hotkeyType.displayName)
                .font(.title2)
                .fontWeight(.bold)

            // 説明
            Text(hotkeyType.hotkeyDescription)
                .foregroundColor(.secondary)

            // キー設定ボタン
            ShortcutKeyButton(
                keyCombo: $keyCombo,
                defaultKeyCombo: hotkeyType.defaultKeyCombo,
                isRecording: isRecording,
                onStartRecording: onStartRecording,
                onStopRecording: onStopRecording,
                onResetToDefault: onResetToDefault
            )

            // 競合警告
            if let conflict = hotkeyConflict {
                Label(conflict, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .accessibilityLabel("ホットキー競合警告: \(conflict)")
            }

            Spacer()

            // 注意メッセージ
            Label(
                "他のアプリと競合する場合は変更してください",
                systemImage: "exclamationmark.triangle"
            )
            .foregroundColor(.secondary)
            .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
