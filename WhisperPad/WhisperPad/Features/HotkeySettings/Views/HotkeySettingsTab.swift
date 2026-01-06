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
    @Bindable var store: StoreOf<HotkeySettingsFeature>
    @Environment(\.locale) private var locale
    @Environment(\.appLocale) private var appLocale

    var body: some View {
        MasterDetailLayout(
            primary: { shortcutListPanel },
            detail: { detailPanel }
        )
        .onAppear {
            // 初期選択
            if store.selectedShortcut == nil {
                store.send(.selectShortcut(.recording))
            }
        }
        .environment(\.locale, store.preferredLocale.locale)
        .hotkeyConflictAlertsForHotkeySettings(store: store)
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
                            keyCombo: keyCombo(for: hotkeyType),
                            appLocale: appLocale
                        )
                        .tag(hotkeyType)
                    }
                } header: {
                    Text(appLocale.localized(String.LocalizationValue(category.localizationKey)))
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
                menuBarIconSettings: store.menuBarIconSettings,
                isRecording: store.recordingHotkeyType == selected,
                onStartRecording: { store.send(.startRecordingHotkey(selected)) },
                onStopRecording: { store.send(.stopRecordingHotkey) },
                onResetToDefault: { resetToDefault(selected) },
                hotkeyConflict: store.hotkeyConflict,
                appLocale: appLocale
            )
        } else {
            placeholderView
        }
    }

    /// プレースホルダービュー
    private var placeholderView: some View {
        VStack {
            Spacer()
            Text(appLocale.localized("hotkey.select_prompt"))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    /// 指定されたショートカットタイプのキーコンボを取得
    private func keyCombo(for type: HotkeyType) -> HotKeySettings.KeyComboSettings {
        switch type {
        case .recording:
            store.hotKey.recordingHotKey
        case .recordingPause:
            store.hotKey.recordingPauseHotKey
        case .cancel:
            store.hotKey.cancelHotKey
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
        var hotKey = store.hotKey
        switch type {
        case .recording:
            hotKey.recordingHotKey = .recordingDefault
        case .recordingPause:
            hotKey.recordingPauseHotKey = .recordingPauseDefault
        case .cancel:
            hotKey.cancelHotKey = .cancelDefault
        }
        store.send(.updateHotKeySettings(hotKey))
    }
}

// MARK: - ShortcutListRow

/// ショートカット一覧の行
private struct ShortcutListRow: View {
    let hotkeyType: HotkeyType
    let keyCombo: HotKeySettings.KeyComboSettings
    let appLocale: AppLocale

    var body: some View {
        HStack {
            Text(appLocale.localized(String.LocalizationValue(hotkeyType.localizationKey)))
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
        .accessibilityLabel(
            appLocale.localized(String.LocalizationValue(hotkeyType.localizationKey)) + ", " +
                appLocale.localized("hotkey.accessibility.shortcut_label") +
                keyCombo.displayString
        )
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
    let appLocale: AppLocale

    /// アイコン設定
    private var iconConfig: StatusIconConfig {
        menuBarIconSettings.config(for: hotkeyType.correspondingIconStatus)
    }

    var body: some View {
        DetailPanelContainer {
            // ヘッダー：アイコンとタイトル
            DetailHeaderSection(
                symbolName: iconConfig.symbolName,
                symbolColor: Color(iconConfig.color),
                title: appLocale.localized(String.LocalizationValue(hotkeyType.localizationKey)),
                category: appLocale.localized(String.LocalizationValue(hotkeyType.category.localizationKey)),
                onReset: onResetToDefault,
                resetHelpText: appLocale.localized("hotkey.reset.help")
            )

            Divider()

            // 説明セクション
            DetailDescriptionSection(
                descriptionText: appLocale.localized(String.LocalizationValue(hotkeyType.descriptionLocalizationKey)),
                labelText: appLocale.localized("common.description")
            )

            // ショートカット入力セクション
            ShortcutEditSection(
                keyCombo: $keyCombo,
                defaultKeyCombo: hotkeyType.defaultKeyCombo,
                hotkeyType: hotkeyType,
                isRecording: isRecording,
                hotkeyConflict: hotkeyConflict,
                onStartRecording: onStartRecording,
                onStopRecording: onStopRecording,
                onResetToDefault: onResetToDefault,
                appLocale: appLocale
            )
        }
    }
}

// MARK: - Preview

#Preview {
    HotkeySettingsTab(
        store: Store(initialState: HotkeySettingsFeature.State()) {
            HotkeySettingsFeature()
        }
    )
    .frame(width: 520, height: 400)
}
