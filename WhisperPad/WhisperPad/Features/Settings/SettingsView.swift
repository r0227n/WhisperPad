//
//  SettingsView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 設定画面のルートビュー
///
/// ピル型タブで一般設定、ホットキー設定、録音設定、モデル設定、出力設定を切り替えます。
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    private var preferredLocale: AppLocale {
        store.settings.general.preferredLocale
    }

    var body: some View {
        VStack(spacing: 0) {
            // ピル型タブセレクター
            PillTabSelector(
                selectedTab: $store.selectedTab.sending(\.selectTab),
                locale: preferredLocale
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // タブコンテンツ
            tabContent
        }
        .frame(width: 650, height: 550)
        .environment(\.locale, preferredLocale.locale)
        .environment(\.appLocale, preferredLocale)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .general:
            GeneralSettingsTab(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            )

        case .icon:
            IconSettingsTab(
                store: store.scope(state: \.iconSettings, action: \.iconSettings)
            )

        case .hotkey:
            HotkeySettingsTab(
                store: store.scope(state: \.hotkeySettings, action: \.hotkeySettings)
            )

        case .recording:
            RecordingSettingsTab(
                store: store.scope(state: \.recordingSettings, action: \.recordingSettings),
                locale: preferredLocale.locale
            )

        case .model:
            ModelSettingsTab(
                store: store.scope(state: \.modelSettings, action: \.modelSettings)
            )
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
