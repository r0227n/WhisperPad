//
//  SilenceDetectionSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 無音検出セクション
///
/// 無音検出設定を表示するコンポーネント。
struct SilenceDetectionSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // セクションヘッダーとトグル
                HStack(spacing: 8) {
                    // アイコン
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange)
                        .frame(width: 20)

                    // タイトル
                    Text("recording.silence_detection.title", comment: "Auto-stop on silence")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    // トグル
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { store.settings.recording.silenceDetectionEnabled },
                            set: { enabled in
                                var recording = store.settings.recording
                                recording.silenceDetectionEnabled = enabled
                                store.send(.updateRecordingSettings(recording))
                            }
                        )
                    )
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help(String(localized: "recording.silence_detection.help", comment: "Auto-stop help"))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    String(localized: "recording.silence_detection.title", comment: "Auto-stop on silence")
                )
                .accessibilityHint(
                    String(localized: "recording.silence_detection.accessibility_hint", comment: "Toggle hint")
                )

                if store.settings.recording.silenceDetectionEnabled {
                    Divider()

                    // 無音判定時間
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("recording.silence_detection.duration", comment: "Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            TextField(
                                String(localized: "recording.silence_detection.seconds", comment: "seconds"),
                                value: Binding(
                                    get: { store.settings.recording.silenceDuration },
                                    set: { newValue in
                                        var recording = store.settings.recording
                                        recording.silenceDuration = newValue
                                        store.send(.updateRecordingSettings(recording))
                                    }
                                ),
                                format: .number
                            )
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(
                                String(
                                    localized: "recording.silence_detection.duration_accessibility",
                                    comment: "Silence duration"
                                )
                            )
                            .accessibilityHint(
                                String(
                                    localized: "recording.silence_detection.duration_hint",
                                    comment: "Duration in seconds"
                                )
                            )

                            Text("recording.silence_detection.seconds", comment: "seconds")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "recording.silence_detection.accessibility", comment: "Silence detection settings")
        )
    }
}

// MARK: - Preview

#Preview("Enabled") {
    SilenceDetectionSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: true,
                        silenceDuration: 3.0
                    )
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Disabled") {
    SilenceDetectionSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: false
                    )
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}
