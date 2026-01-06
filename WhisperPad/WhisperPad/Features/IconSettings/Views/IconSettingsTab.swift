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
    @Bindable var store: StoreOf<IconSettingsFeature>

    var body: some View {
        MasterDetailLayout(
            detailMinWidth: 300,
            primary: { iconListPanel },
            detail: { detailPanel }
        )
        .environment(\.locale, store.preferredLocale.locale)
    }

    // MARK: - Left Panel

    /// アイコン一覧パネル
    private var iconListPanel: some View {
        List(selection: Binding(
            get: { store.selectedStatus },
            set: { newValue in
                if let status = newValue {
                    store.send(.selectStatus(status))
                }
            }
        )) {
            Section {
                ForEach(IconConfigStatus.allCases) { status in
                    IconListRow(
                        status: status,
                        config: store.iconSettings.config(for: status)
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
            status: store.selectedStatus,
            config: store.bindingForIconConfig(status: store.selectedStatus),
            onReset: { store.send(.resetIconSetting(store.selectedStatus)) }
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
        store: Store(initialState: IconSettingsFeature.State()) {
            IconSettingsFeature()
        }
    )
    .frame(width: 650, height: 550)
}
