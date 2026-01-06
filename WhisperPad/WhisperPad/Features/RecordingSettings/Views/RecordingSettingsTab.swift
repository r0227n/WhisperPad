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
    @Bindable var store: StoreOf<RecordingSettingsFeature>

    /// 現在のロケール（親から渡される）
    var locale: Locale = .current

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
        .environment(\.locale, locale)
    }
}

// MARK: - Preview

#Preview {
    RecordingSettingsTab(
        store: Store(initialState: RecordingSettingsFeature.State()) {
            RecordingSettingsFeature()
        }
    )
    .frame(width: 650, height: 550)
}
