//
//  AudioInputSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// オーディオ入力セクション
///
/// 入力デバイス選択とリアルタイムオーディオレベルメーターを表示するコンポーネント。
/// AudioRecorderClient.observeAudioLevel() を使用してリアルタイム更新を行います。
struct AudioInputSection: View {
    @Bindable var store: StoreOf<SettingsFeature>
    /// 現在の音声レベル（dB）
    let currentLevel: Float

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // セクションヘッダー
                SettingSectionHeader(
                    icon: "waveform",
                    iconColor: .blue,
                    title: "Audio Input",
                    helpText: "Select the microphone to use for recording and monitor input levels"
                )

                // 入力デバイス選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Device")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker(
                        "",
                        selection: Binding(
                            get: { store.settings.recording.inputDeviceID },
                            set: { newValue in
                                var recording = store.settings.recording
                                recording.inputDeviceID = newValue
                                store.send(.updateRecordingSettings(recording))
                            }
                        )
                    ) {
                        Text("System Default").tag(nil as String?)

                        ForEach(store.availableInputDevices) { device in
                            HStack {
                                Text(device.name)
                                if device.isDefault {
                                    Text("(Default)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(device.id as String?)
                        }
                    }
                    .labelsHidden()
                    .help("Select the microphone to use for recording")
                }

                Divider()

                // 音声レベルメーター
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        InfoPopoverButton(
                            helpText: """
                            Real-time audio input level. Speak into your microphone to see \
                            the meter respond. Green is good, yellow is loud, and red is too loud.
                            """,
                            title: "About Input Levels"
                        )

                        Spacer()

                        if currentLevel > -60 {
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Silent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    AudioLevelMeter(
                        level: currentLevel,
                        showNumericValue: true,
                        height: 10
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Audio input settings")
    }
}

// MARK: - Preview

#Preview("Default Device") {
    AudioInputSection(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        },
        currentLevel: -20
    )
    .padding()
    .frame(width: 500)
}

#Preview("With Level Variations") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Silent")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -60
            )

            Text("Quiet")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -40
            )

            Text("Normal")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -20
            )

            Text("Good")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -12
            )

            Text("Loud")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -6
            )

            Text("Peak")
                .font(.headline)
            AudioInputSection(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                },
                currentLevel: -3
            )
        }
        .padding()
    }
    .frame(width: 500, height: 800)
}
