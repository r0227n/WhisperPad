//
//  SettingsView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 設定画面のルートビュー
///
/// タブ形式で一般設定、ホットキー設定、録音設定、モデル設定、出力設定を表示します。
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    private var preferredLocale: AppLocale {
        store.settings.general.preferredLocale
    }

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            GeneralSettingsTab(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            )
            .settingsTabItem(.general, locale: preferredLocale)

            IconSettingsTab(
                store: store.scope(state: \.iconSettings, action: \.iconSettings)
            )
            .settingsTabItem(.icon, locale: preferredLocale)

            HotkeySettingsTab(
                store: store.scope(state: \.hotkeySettings, action: \.hotkeySettings)
            )
            .settingsTabItem(.hotkey, locale: preferredLocale)

            RecordingSettingsTab(
                store: store.scope(state: \.recordingSettings, action: \.recordingSettings),
                locale: preferredLocale.locale
            )
            .settingsTabItem(.recording, locale: preferredLocale)

            ModelSettingsTab(
                store: store.scope(state: \.modelSettings, action: \.modelSettings)
            )
            .settingsTabItem(.model, locale: preferredLocale)
        }
        .frame(width: 650, height: 550)
        .environment(\.locale, preferredLocale.locale)
        .environment(\.appLocale, preferredLocale)
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Tab Item View Modifier

private extension View {
    /// SettingsTab用のタブアイテムを設定するView modifier
    ///
    /// - Parameters:
    ///   - tab: 設定するタブ
    ///   - locale: ローカライズに使用するAppLocale
    /// - Returns: タブアイテムが設定されたView
    func settingsTabItem(_ tab: SettingsTab, locale: AppLocale) -> some View {
        self
            .tabItem {
                Label {
                    Text(tab.localizedTitle(for: locale))
                } icon: {
                    Image(systemName: tab.iconName)
                }
            }
            .tag(tab)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
