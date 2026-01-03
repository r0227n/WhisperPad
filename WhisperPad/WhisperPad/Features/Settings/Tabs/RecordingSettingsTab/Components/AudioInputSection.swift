//
//  AudioInputSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// オーディオ入力セクション
///
/// 入力デバイス選択を提供するコンポーネント。
struct AudioInputSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        SettingCard {
            HStack(alignment: .center, spacing: 16) {
                // セクションヘッダー
                SettingSectionHeader(
                    icon: "waveform",
                    iconColor: .blue,
                    title: String(localized: "recording.input_device.title", comment: "Input Device")
                )

                Spacer()

                // 入力デバイス選択
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
                    Text("recording.input_device.system_default", comment: "System Default").tag(nil as String?)

                    ForEach(store.availableInputDevices) { device in
                        HStack {
                            Text(device.name)
                            if device.isDefault {
                                Text("recording.input_device.default_marker", comment: "(Default)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(device.id as String?)
                    }
                }
                .labelsHidden()
                .help(String(localized: "recording.input_device.help", comment: "Select microphone"))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "recording.input_device.accessibility", comment: "Audio input settings"))
    }
}

// MARK: - Preview

#Preview("Default Device") {
    AudioInputSection(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("With Devices") {
    AudioInputSection(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}
