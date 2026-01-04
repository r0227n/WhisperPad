//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音設定タブ
///
/// 音声録音の設定を行います。
/// 入力デバイス、入力レベルモニター、出力設定、無音検出などを設定できます。
struct RecordingSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. 音声入力セクション
                AudioInputSection(store: store)

                // 2. 出力設定セクション
                OutputSettingsSection(store: store)

                // 3. 入力レベルモニターセクション
                AudioInputMonitorSection(store: store)

                // 4. 無音検出セクション
                SilenceDetectionSection(store: store)
            }
            .padding()
        }
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }
}

// MARK: - Preview

#Preview {
    RecordingSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 650, height: 550)
}
