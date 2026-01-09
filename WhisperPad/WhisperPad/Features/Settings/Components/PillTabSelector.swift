//
//  PillTabSelector.swift
//  WhisperPad
//

import SwiftUI

/// ピル型タブセレクター
///
/// モダンなmacOSアプリ風のピル型タブ切り替えUIを提供します。
/// アニメーション付きのインジケーターが選択中のタブに追従します。
struct PillTabSelector<Tab: Hashable>: View {
    /// 選択中のタブ
    @Binding var selectedTab: Tab

    /// 表示するタブ一覧
    let tabs: [Tab]

    /// タブのラベルを取得するクロージャ
    let label: (Tab) -> String

    /// タブのアイコン名を取得するクロージャ
    let icon: (Tab) -> String

    /// アニメーション用の名前空間
    @Namespace private var animationNamespace

    /// ホバー中のタブ
    @State private var hoveredTab: Tab?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoveredTab == tab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon(tab))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))

                Text(label(tab))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minWidth: 80)
            .background {
                if isSelected {
                    // 選択時のピルインジケーター
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(nsColor: .controlAccentColor).opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color(nsColor: .controlAccentColor).opacity(0.3), lineWidth: 0.5)
                        )
                        .matchedGeometryEffect(id: "pill", in: animationNamespace)
                } else if isHovered {
                    // ホバー時の背景
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                }
            }
            .foregroundStyle(isSelected ? Color(nsColor: .controlAccentColor) : .secondary)
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredTab = hovering ? tab : nil
            }
        }
    }
}

// MARK: - SettingsTab Extension

extension PillTabSelector where Tab == SettingsTab {
    /// SettingsTab用の簡易イニシャライザ
    ///
    /// - Parameters:
    ///   - selectedTab: 選択中のタブ
    ///   - locale: ローカライズに使用するAppLocale
    init(selectedTab: Binding<SettingsTab>, locale: AppLocale) {
        self.init(
            selectedTab: selectedTab,
            tabs: SettingsTab.allCases,
            label: { $0.localizedTitle(for: locale) },
            icon: { $0.iconName }
        )
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    struct PreviewWrapper: View {
        @State private var selectedTab = SettingsTab.general

        var body: some View {
            VStack(spacing: 20) {
                PillTabSelector(selectedTab: $selectedTab, locale: .system)

                Text("Selected: \(selectedTab.displayName)")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 650)
        }
    }
    return PreviewWrapper()
}

#Preview("Dark Mode") {
    struct PreviewWrapper: View {
        @State private var selectedTab = SettingsTab.hotkey

        var body: some View {
            VStack(spacing: 20) {
                PillTabSelector(selectedTab: $selectedTab, locale: .system)

                Text("Selected: \(selectedTab.displayName)")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 650)
        }
    }
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Japanese") {
    struct PreviewWrapper: View {
        @State private var selectedTab = SettingsTab.recording

        var body: some View {
            VStack(spacing: 20) {
                PillTabSelector(selectedTab: $selectedTab, locale: .ja)

                Text("Selected: \(selectedTab.displayName)")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 650)
        }
    }
    return PreviewWrapper()
}
