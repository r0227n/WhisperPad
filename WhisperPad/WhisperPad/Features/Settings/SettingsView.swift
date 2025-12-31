//
//  SettingsView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 設定画面のルートビュー
///
/// タブ形式で一般設定、モデル設定、出力設定を表示します。
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            GeneralSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.iconName)
                }
                .tag(SettingsTab.general)

            ModelSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.model.rawValue, systemImage: SettingsTab.model.iconName)
                }
                .tag(SettingsTab.model)

            OutputSettingsTab(store: store)
                .tabItem {
                    Label(SettingsTab.output.rawValue, systemImage: SettingsTab.output.iconName)
                }
                .tag(SettingsTab.output)
        }
        .frame(width: 500, height: 450)
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
