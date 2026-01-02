//
//  SilenceDetectionSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 無音検出セクション
///
/// 無音検出設定を表示し、インタラクティブなしきい値設定を提供するコンポーネント。
/// リアルタイムプレビューで現在の音声レベルと設定値を比較表示します。
struct SilenceDetectionSection: View {
    @Bindable var store: StoreOf<SettingsFeature>
    /// 現在の音声レベル（dB）
    let currentLevel: Float

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // セクションヘッダー
                SettingSectionHeader(
                    icon: "speaker.slash.fill",
                    iconColor: .orange,
                    title: "Silence Detection",
                    helpText: "Automatically stop recording when silence is detected for a specified duration"
                )

                // 無音検出の有効/無効
                Toggle(
                    "Auto-stop on silence",
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
                .help("Automatically stop recording when silence is detected")

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

                    // 無音判定しきい値
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Threshold")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(Int(store.settings.recording.silenceThreshold)) dB")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        // しきい値の視覚化
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 背景バー
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                // しきい値マーカー
                                let thresholdPosition = thresholdPositionOnBar(
                                    threshold: store.settings.recording.silenceThreshold,
                                    in: geometry.size.width
                                )

                                Rectangle()
                                    .fill(Color.orange.opacity(0.5))
                                    .frame(width: 2, height: 16)
                                    .position(x: thresholdPosition, y: 8)
                            }
                        }
                        .frame(height: 16)

                        // 現在のレベルとしきい値の比較
                        HStack {
                            Text("Current Level:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            AudioLevelMeter(
                                level: currentLevel,
                                showNumericValue: false,
                                height: 6
                            )

                            if currentLevel < store.settings.recording.silenceThreshold {
                                Text("(Silence)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("(Active)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Silence detection settings")
    }

    // MARK: - Private Methods

    /// しきい値のバー上の位置を計算
    private func thresholdPositionOnBar(threshold: Float, in width: CGFloat) -> CGFloat {
        // -60dB to 0dB を 0 to width にマッピング
        let normalizedPosition = (threshold + 60) / 60
        return width * CGFloat(normalizedPosition)
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
                        silenceThreshold: -40.0,
                        silenceDuration: 3.0
                    )
                )
            )
        ) {
            SettingsFeature()
        },
        currentLevel: -20
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
        },
        currentLevel: -20
    )
    .padding()
    .frame(width: 500)
}

#Preview("Silence Detected") {
    SilenceDetectionSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: true,
                        silenceThreshold: -40.0,
                        silenceDuration: 3.0
                    )
                )
            )
        ) {
            SettingsFeature()
        },
        currentLevel: -55
    )
    .padding()
    .frame(width: 500)
}

#Preview("Active Audio") {
    SilenceDetectionSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    recording: RecordingSettings(
                        silenceDetectionEnabled: true,
                        silenceThreshold: -40.0,
                        silenceDuration: 3.0
                    )
                )
            )
        ) {
            SettingsFeature()
        },
        currentLevel: -12
    )
    .padding()
    .frame(width: 500)
}
