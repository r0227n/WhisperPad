//
//  AudioInputMonitorSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 音声入力レベルモニターセクション
///
/// リアルタイムの音声レベル表示とマイクテスト機能を提供します。
struct AudioInputMonitorSection: View {
    @Bindable var store: StoreOf<RecordingSettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                SettingSectionHeader(
                    icon: "waveform.circle",
                    iconColor: .blue,
                    title: "recording.monitor.title"
                )

                Divider()

                // 音声レベルメーター
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("recording.monitor.level", comment: "Audio Level")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(store.currentAudioLevel)) dB")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    AudioLevelMeter(
                        level: store.currentAudioLevel,
                        showNumericValue: false,
                        height: 12
                    )
                    .accessibilityLabel(String(
                        localized: "recording.monitor.level.accessibility",
                        comment: "Audio level"
                    ))
                    .accessibilityValue(String(
                        format: String(localized: "recording.monitor.level.accessibility.value"),
                        Int(store.currentAudioLevel)
                    ))
                }

                // マイクテストボタン
                HStack(spacing: 12) {
                    StatusBadge(
                        status: store.isMonitoringAudio ? .recording : .ready,
                        shouldPulse: store.isMonitoringAudio,
                        size: 14
                    )

                    Button(
                        action: {
                            store.send(.toggleAudioMonitoring)
                        },
                        label: {
                            Text(
                                store.isMonitoringAudio
                                    ? "recording.monitor.stop"
                                    : "recording.monitor.start",
                                comment: store.isMonitoringAudio ? "Stop Test" : "Test Microphone"
                            )
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .tint(store.isMonitoringAudio ? .orange : .blue)
                    .accessibilityLabel(
                        store.isMonitoringAudio
                            ? String(localized: "recording.monitor.stop", comment: "Stop Test")
                            : String(localized: "recording.monitor.start", comment: "Test Microphone")
                    )

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Monitoring off
        AudioInputMonitorSection(
            store: Store(initialState: RecordingSettingsFeature.State()) {
                RecordingSettingsFeature()
            }
        )

        // Monitoring on
        AudioInputMonitorSection(
            store: Store(
                initialState: RecordingSettingsFeature.State(
                    currentAudioLevel: -20.0,
                    isMonitoringAudio: true
                )
            ) {
                RecordingSettingsFeature()
            }
        )
    }
    .padding()
    .frame(width: 500)
}
