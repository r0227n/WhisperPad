//
//  IconSettingsTab.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import SwiftUI

/// アイコン設定タブ
///
/// マスター・ディテール形式でメニューバーアイコンの設定を行います。
/// 左パネル：状態別アイコン一覧
/// 右パネル：選択した状態の詳細と編集
struct IconSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    /// 選択中の状態
    @State private var selectedStatus: IconConfigStatus = .idle

    var body: some View {
        MasterDetailLayout(
            detailMinWidth: 300,
            primary: { iconListPanel },
            detail: { detailPanel }
        )
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }

    // MARK: - Left Panel

    /// アイコン一覧パネル
    private var iconListPanel: some View {
        List(selection: $selectedStatus) {
            Section {
                ForEach(IconConfigStatus.allCases) { status in
                    IconListRow(
                        status: status,
                        config: store.settings.general.menuBarIconSettings.config(for: status)
                    )
                    .tag(status)
                }
            } header: {
                Text("icon.status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Right Panel

    /// 詳細パネル
    private var detailPanel: some View {
        IconDetailPanel(
            status: selectedStatus,
            config: binding(for: selectedStatus),
            onReset: { store.send(.resetIconSetting(selectedStatus)) }
        )
    }

    // MARK: - Helpers

    /// 状態に対応するアイコン設定のバインディングを作成
    /// - Parameter status: 状態タイプ
    /// - Returns: StatusIconConfig のバインディング
    private func binding(for status: IconConfigStatus) -> Binding<StatusIconConfig> {
        Binding(
            get: {
                store.settings.general.menuBarIconSettings.config(for: status)
            },
            set: { newConfig in
                var settings = store.settings.general.menuBarIconSettings
                settings.setConfig(newConfig, for: status)
                var general = store.settings.general
                general.menuBarIconSettings = settings
                store.send(.updateGeneralSettings(general))
            }
        )
    }
}

// MARK: - IconListRow

/// アイコン一覧の行
private struct IconListRow: View {
    let status: IconConfigStatus
    let config: StatusIconConfig

    var body: some View {
        HStack(spacing: 12) {
            // アイコンプレビュー
            Image(systemName: config.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(nsColor: config.color))
                .font(.system(size: 18))
                .frame(width: 24, height: 24)

            // 状態名
            Text(LocalizedStringKey(status.localizedKey))
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityLabel(
            String(
                localized: "icon.accessibility.label",
                defaultValue: "\(status.displayName) icon",
                comment: "Icon status accessibility label"
            )
        )
    }
}

// MARK: - IconDetailPanel

/// アイコン詳細パネル
private struct IconDetailPanel: View {
    let status: IconConfigStatus
    @Binding var config: StatusIconConfig
    let onReset: () -> Void

    /// SwiftUI Color として管理（NSColor との同期用）
    @State private var selectedColor: Color

    init(
        status: IconConfigStatus,
        config: Binding<StatusIconConfig>,
        onReset: @escaping () -> Void
    ) {
        self.status = status
        self._config = config
        self.onReset = onReset
        self._selectedColor = State(initialValue: Color(nsColor: config.wrappedValue.color))
    }

    var body: some View {
        DetailPanelContainer {
            // ヘッダー: アイコンとタイトル
            DetailHeaderSection(
                symbolName: config.symbolName,
                symbolColor: Color(nsColor: config.color),
                title: LocalizedStringKey(status.localizedKey),
                onReset: onReset,
                resetHelpText: String(localized: "icon.reset", comment: "Reset this status")
            )

            Divider()

            // 説明セクション
            DetailDescriptionSection(
                descriptionText: LocalizedStringKey(status.descriptionKey)
            )

            // アイコン編集セクション
            IconEditSection(symbolName: $config.symbolName)

            // 色編集セクション
            ColorEditSection(
                selectedColor: $selectedColor,
                nsColor: $config.color
            )
        }
    }
}

// MARK: - Preview

#Preview {
    IconSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 650, height: 550)
}
