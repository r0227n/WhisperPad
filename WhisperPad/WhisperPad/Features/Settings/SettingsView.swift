//
//  SettingsView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Settings root view
///
/// Displays general settings, hotkey settings, recording settings, model settings, and output settings in tabs.
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            GeneralSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.general.displayName, systemImage: SettingsTab.general.iconName)
                }
                .tag(SettingsTab.general)

            IconSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.icon.displayName, systemImage: SettingsTab.icon.iconName)
                }
                .tag(SettingsTab.icon)

            HotkeySettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.hotkey.displayName, systemImage: SettingsTab.hotkey.iconName)
                }
                .tag(SettingsTab.hotkey)

            RecordingSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.recording.displayName, systemImage: SettingsTab.recording.iconName)
                }
                .tag(SettingsTab.recording)

            ModelSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.model.displayName, systemImage: SettingsTab.model.iconName)
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
