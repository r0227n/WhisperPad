//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音設定タブ
///
/// 音声録音の設定を行います。
/// モダンミニマルなデザインで、情報の整理・視覚的な魅力・操作性・状態可視化を改善しました。
struct RecordingSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @State private var currentAudioLevel: Float = -60.0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // オーディオ入力セクション
                AudioInputSection(store: store)

                // 出力設定セクション
                OutputSettingsSection(store: store)

                // 無音検出セクション
                SilenceDetectionSection(
                    store: store,
                    currentLevel: currentAudioLevel
                )
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .task {
            // オーディオレベル監視を開始
            await observeAudioLevels()
        }
    }

    // MARK: - Private Methods

    /// オーディオレベルを監視
    private func observeAudioLevels() async {
        @Dependency(\.audioRecorder) var audioRecorder

        for await level in audioRecorder.observeAudioLevel() {
            currentAudioLevel = level
        }
    }
}

// MARK: - Preview

#Preview {
    RecordingSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 600, height: 700)
}

#Preview("With Recording") {
    RecordingSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: true,
                        silenceThreshold: -40.0,
                        silenceDuration: 3.0
                    ),
                    output: {
                        var settings = FileOutputSettings.default
                        settings.isEnabled = true
                        settings.copyToClipboard = true
                        return settings
                    }()
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 600, height: 700)
}

#Preview("Minimal Settings") {
    RecordingSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: false
                    ),
                    output: {
                        var settings = FileOutputSettings.default
                        settings.isEnabled = false
                        settings.copyToClipboard = true
                        return settings
                    }()
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 600, height: 700)
}
