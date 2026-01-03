//
//  HotkeySettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ショートカット設定タブ
///
/// マスター・ディテール形式でグローバルショートカットの設定を行います。
/// 左パネル：カテゴリ別ショートカット一覧
/// 右パネル：選択したショートカットの詳細と編集
struct HotkeySettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        HSplitView {
            // 左パネル: ショートカット一覧
            shortcutListPanel
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)

            // 右パネル: 詳細
            detailPanel
                .frame(minWidth: 280)
        }
        .onAppear {
            // 初期選択
            if store.selectedShortcut == nil {
                store.send(.selectShortcut(.recording))
            }
        }
        .alert(
            "ホットキー登録失敗",
            isPresented: Binding(
                get: { store.showHotkeyConflictAlert },
                set: { if !$0 { store.send(.dismissConflictAlert) } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.send(.dismissConflictAlert)
            }
        } message: {
            if let type = store.conflictingHotkeyType {
                Text("\(type.displayName) のショートカットは他のアプリケーションで使用中のため、登録できません。別のキーコンビネーションを選択してください。")
            } else {
                Text("他のアプリケーションで使用中のため、登録できません。")
            }
        }
        .alert(
            "ホットキーが重複しています",
            isPresented: Binding(
                get: { store.showDuplicateHotkeyAlert },
                set: { if !$0 { store.send(.dismissDuplicateAlert) } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.send(.dismissDuplicateAlert)
            }
        } message: {
            if let targetType = store.conflictingHotkeyType,
               let duplicateType = store.duplicateWithHotkeyType {
                Text("""
                \(targetType.displayName) のショートカットは、既に \(duplicateType.displayName) で使用されています。

                別のキーコンビネーションを選択してください。
                """)
            } else {
                Text("このショートカットは既に別の機能で使用されています。")
            }
        }
        .alert(
            "システムショートカット",
            isPresented: Binding(
                get: { store.showSystemReservedAlert },
                set: { if !$0 { store.send(.dismissSystemReservedAlert) } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.send(.dismissSystemReservedAlert)
            }
        } message: {
            if let type = store.conflictingHotkeyType {
                Text("""
                \(type.displayName) のショートカットには、システムで予約されているキーコンビネーション（Cmd+C、Cmd+Vなど）を使用できません。

                別のキーコンビネーションを選択してください。
                """)
            } else {
                Text("このショートカットはシステムで予約されています。")
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

    /// 指定されたショートカットタイプのキーコンボを取得
    private func keyCombo(for type: HotkeyType) -> HotKeySettings.KeyComboSettings {
        switch type {
        case .recording:
            store.settings.hotKey.recordingHotKey
        case .recordingPause:
            store.settings.hotKey.recordingPauseHotKey
        case .cancel:
            store.settings.hotKey.cancelHotKey
        case .popupCopyAndClose:
            store.settings.hotKey.popupCopyAndCloseHotKey
        case .popupSaveToFile:
            store.settings.hotKey.popupSaveToFileHotKey
        case .popupClose:
            store.settings.hotKey.popupCloseHotKey
        }
    }

    /// 指定されたショートカットタイプのキーコンボBindingを取得
    private func keyComboBinding(for type: HotkeyType) -> Binding<HotKeySettings.KeyComboSettings> {
        Binding(
            get: { keyCombo(for: type) },
            set: { newValue in
                // システム競合検証を含む更新処理
                store.send(.validateAndUpdateHotkey(type, newValue))
            }
        )
    }

    /// デフォルトにリセット
    private func resetToDefault(_ type: HotkeyType) {
        var hotKey = store.settings.hotKey
        switch type {
        case .recording:
            hotKey.recordingHotKey = .recordingDefault
        case .recordingPause:
            hotKey.recordingPauseHotKey = .recordingPauseDefault
        case .cancel:
            hotKey.cancelHotKey = .cancelDefault
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

/// ショートカット一覧の行
private struct ShortcutListRow: View {
    let hotkeyType: HotkeyType
    let keyCombo: HotKeySettings.KeyComboSettings

    var body: some View {
        HStack {
            Text(hotkeyType.displayName)
                .lineLimit(1)

            Spacer()

            // キーコンボをバッジスタイルで表示
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
        .accessibilityLabel("\(hotkeyType.displayName)、ショートカット: \(keyCombo.displayString)")
    }
}

// MARK: - ShortcutDetailPanel

/// ショートカット詳細パネル
private struct ShortcutDetailPanel: View {
    let hotkeyType: HotkeyType
    @Binding var keyCombo: HotKeySettings.KeyComboSettings
    let menuBarIconSettings: MenuBarIconSettings
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onResetToDefault: () -> Void
    let hotkeyConflict: String?

    /// アイコン設定
    private var iconConfig: StatusIconConfig {
        menuBarIconSettings.config(for: hotkeyType.correspondingIconStatus)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー：アイコンとタイトル
                headerSection

                Divider()

                // 説明セクション
                descriptionSection

                // ショートカット入力セクション
                shortcutInputSection

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// ヘッダーセクション
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

                Text(hotkeyType.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onResetToDefault()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .help("この状態をリセット")
        }
    }

    /// 説明セクション
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("説明", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(hotkeyType.hotkeyDescription)
                .foregroundColor(.primary)
        }
    }

    /// ショートカット入力セクション
    private var shortcutInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("ショートカットキー", systemImage: "keyboard")
                .font(.headline)
                .foregroundColor(.secondary)

            // キー設定ボタン
            ShortcutKeyButton(
                keyCombo: $keyCombo,
                defaultKeyCombo: hotkeyType.defaultKeyCombo,
                hotkeyType: hotkeyType,
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
                    .accessibilityLabel("ショートカット競合警告: \(conflict)")
            }

            // 注意メッセージ
            Text("他のアプリと競合する場合は変更してください")
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
