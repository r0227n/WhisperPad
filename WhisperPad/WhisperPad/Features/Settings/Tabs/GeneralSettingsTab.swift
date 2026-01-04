//
//  GeneralSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 一般設定タブ
///
/// アプリケーションの基本的な動作設定を行います。
/// 2つのセクションで構成: 基本設定、通知・パフォーマンス
struct GeneralSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. 基本設定セクション
                BasicSettingsSection(store: store)

                // 2. 通知・パフォーマンスセクション
                NotificationPerformanceSection(store: store)
            }
            .padding()
        }
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 500)
}
