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

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            GeneralSettingsTab(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            )
            .tabItem {
                Label {
                    Text("settings.tab.general")
                } icon: {
                    Image(systemName: SettingsTab.general.iconName)
                }
            }
            .tag(SettingsTab.general)

            IconSettingsTab(
                store: store.scope(state: \.iconSettings, action: \.iconSettings)
            )
            .tabItem {
                Label {
                    Text("settings.tab.icon")
                } icon: {
                    Image(systemName: SettingsTab.icon.iconName)
                }
            }
            .tag(SettingsTab.icon)

            HotkeySettingsTab(
                store: store.scope(state: \.hotkeySettings, action: \.hotkeySettings)
            )
            .tabItem {
                Label {
                    Text("settings.tab.hotkey")
                } icon: {
                    Image(systemName: SettingsTab.hotkey.iconName)
                }
            }
            .tag(SettingsTab.hotkey)

            RecordingSettingsTab(
                store: store.scope(state: \.recordingSettings, action: \.recordingSettings),
                locale: store.settings.general.preferredLocale.locale
            )
            .tabItem {
                Label {
                    Text("settings.tab.recording")
                } icon: {
                    Image(systemName: SettingsTab.recording.iconName)
                }
            }
            .tag(SettingsTab.recording)

            ModelSettingsTab(
                store: store.scope(state: \.modelSettings, action: \.modelSettings)
            )
            .tabItem {
                Label {
                    Text("settings.tab.model")
                } icon: {
                    Image(systemName: SettingsTab.model.iconName)
                }
            }
            .tag(SettingsTab.model)
        }
        .frame(width: 650, height: 550)
        .environment(\.locale, store.settings.general.preferredLocale.locale)
        .onAppear {
            store.send(.onAppear)
        }
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
