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
                    Text("Auto-stop on silence")
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
                    .help("Automatically stop recording when silence is detected")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Auto-stop on silence")
                .accessibilityHint("Toggle to enable or disable automatic recording stop on silence detection")

                if store.settings.recording.silenceDetectionEnabled {
                    Divider()

                    // 無音判定時間
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            TextField(
                                "seconds",
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
                            .accessibilityLabel("Silence duration")
                            .accessibilityHint("Duration in seconds")

                            Text("seconds")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Silence detection settings")
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
