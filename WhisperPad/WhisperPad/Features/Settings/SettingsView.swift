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
            GeneralSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.iconName)
                }
                .tag(SettingsTab.general)

            IconSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.icon.rawValue, systemImage: SettingsTab.icon.iconName)
                }
                .tag(SettingsTab.icon)

            HotkeySettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.hotkey.rawValue, systemImage: SettingsTab.hotkey.iconName)
                }
                .tag(SettingsTab.hotkey)

            RecordingSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.recording.rawValue, systemImage: SettingsTab.recording.iconName)
                }
                .tag(SettingsTab.recording)

            ModelSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.model.rawValue, systemImage: SettingsTab.model.iconName)
                }
                .tag(SettingsTab.model)
        }
        .frame(width: 520, height: 500)
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
