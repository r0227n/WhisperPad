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
        HSplitView {
            // 左パネル: アイコン状態一覧
            iconListPanel
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)

            // 右パネル: 詳細
            detailPanel
                .frame(minWidth: 300)
        }
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
                Text("icon.status", comment: "Icon Status")
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
            Text(status.rawValue)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityLabel(
            String(
                localized: "icon.accessibility.label",
                defaultValue: "\(status.rawValue) icon",
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

    /// プリセット色
    private let presetColors: [NSColor] = [
        .systemGray,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemBlue,
        .systemGreen,
        .systemPurple
    ]

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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー: アイコンとタイトル
                headerSection

                Divider()

                // 説明セクション
                descriptionSection

                // アイコン編集セクション
                iconEditSection

                // 色編集セクション
                colorEditSection

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: selectedColor) { _, newColor in
            config.color = NSColor(newColor)
        }
        .onChange(of: config.color) { _, newColor in
            let newSwiftUIColor = Color(nsColor: newColor)
            if selectedColor != newSwiftUIColor {
                selectedColor = newSwiftUIColor
            }
        }
        .onChange(of: status) { _, _ in
            selectedColor = Color(nsColor: config.color)
        }
    }

    // MARK: - Sections

    /// ヘッダーセクション
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: config.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(nsColor: config.color))
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(Color(nsColor: config.color).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("icon.menu_bar", comment: "Menu Bar Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .help(String(localized: "icon.reset", comment: "Reset this status"))
        }
    }

    /// 説明セクション
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                String(localized: "icon.description", comment: "Description"),
                systemImage: "info.circle"
            )
            .font(.headline)
            .foregroundColor(.secondary)

            Text(status.detailedDescription)
                .foregroundColor(.primary)
        }
    }

    /// アイコン編集セクション
    private var iconEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "icon.icon", comment: "Icon"),
                systemImage: "star"
            )
            .font(.headline)
            .foregroundColor(.secondary)

            InlineSymbolPicker(selection: $config.symbolName)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    /// 色編集セクション
    private var colorEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "icon.color", comment: "Color"),
                systemImage: "paintpalette"
            )
            .font(.headline)
            .foregroundColor(.secondary)

            HStack(spacing: 8) {
                // ColorPicker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 44, height: 24)

                Divider()
                    .frame(height: 24)

                // プリセット色ボタン
                ForEach(presetColors, id: \.self) { presetColor in
                    presetColorButton(for: presetColor)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    /// プリセット色ボタン
    @ViewBuilder
    private func presetColorButton(for presetColor: NSColor) -> some View {
        let isSelected = config.color.isApproximatelyEqual(to: presetColor)

        Button {
            config.color = presetColor
            selectedColor = Color(nsColor: presetColor)
        } label: {
            Circle()
                .fill(Color(nsColor: presetColor))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    isSelected
                        ? Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        : nil
                )
        }
        .buttonStyle(.plain)
        .help(presetColor.accessibilityName)
        .accessibilityLabel(presetColor.accessibilityName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - NSColor Extension

private extension NSColor {
    /// 2つの色が近似的に等しいかを判定
    func isApproximatelyEqual(to other: NSColor, tolerance: CGFloat = 0.01) -> Bool {
        guard let selfRGB = self.usingColorSpace(.sRGB),
              let otherRGB = other.usingColorSpace(.sRGB)
        else {
            return false
        }

        return abs(selfRGB.redComponent - otherRGB.redComponent) < tolerance
            && abs(selfRGB.greenComponent - otherRGB.greenComponent) < tolerance
            && abs(selfRGB.blueComponent - otherRGB.blueComponent) < tolerance
    }
}

// MARK: - Preview

#Preview {
    IconSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 500)
}
