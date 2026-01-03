//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音設定タブ
///
/// 音声録音の設定を行います。
/// 入力デバイス、出力設定、無音検出などを設定できます。
struct RecordingSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // 入力デバイスセクション
            Section {
                Picker(
                    String(localized: "recording.input_device.title", comment: "Input Device"),
                    selection: Binding(
                        get: { store.settings.recording.inputDeviceID },
                        set: { newValue in
                            var recording = store.settings.recording
                            recording.inputDeviceID = newValue
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                ) {
                    Text(String(localized: "recording.input_device.system_default", comment: "System Default"))
                        .tag(nil as String?)
                    ForEach(store.availableInputDevices) { device in
                        Text(device.name).tag(device.id as String?)
                    }
                }
                .help(String(localized: "recording.input_device.help", comment: "Select microphone"))
                .accessibilityLabel(String(localized: "recording.input_device.title", comment: "Input Device"))
                .accessibilityHint(String(localized: "recording.input_device.help", comment: "Select microphone"))
            } header: {
                Text(String(localized: "recording.input_device.title", comment: "Input Device"))
            }

            // MARK: - 出力セクション

            Section {
                SettingRowWithIcon(
                    icon: "doc.on.clipboard",
                    iconColor: .blue,
                    title: "recording.output.copy_to_clipboard",
                    isOn: Binding(
                        get: { store.settings.output.copyToClipboard },
                        set: { newValue in
                            var output = store.settings.output
                            output.copyToClipboard = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .help(String(localized: "recording.output.copy_to_clipboard.help", comment: "Copies results"))
                .accessibilityLabel(String(
                    localized: "recording.output.copy_to_clipboard",
                    comment: "Copy to Clipboard"
                ))
                .accessibilityHint(String(
                    localized: "recording.output.copy_to_clipboard.help",
                    comment: "Copies results"
                ))

                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 20, alignment: .center)

                    Text(String(localized: "recording.output.save_to_file", comment: "Save to File"))

                    Spacer()

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { store.settings.output.isEnabled },
                            set: { newValue in
                                var output = store.settings.output
                                output.isEnabled = newValue
                                store.send(.updateOutputSettings(output))
                            }
                        )
                    )
                    .labelsHidden()
                    .accessibilityLabel(String(localized: "recording.output.save_to_file", comment: "Save to File"))

                    if store.settings.output.isEnabled {
                        HoverPopoverButton(
                            label: "recording.output.settings",
                            icon: "folder.badge.gearshape"
                        ) {
                            FileOutputDetailsPopover(store: store)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "recording.output.save_to_file", comment: "Save to File"))
                .accessibilityHint(String(localized: "recording.output.save_to_file.help", comment: "Saves results"))
            } header: {
                Label(String(localized: "recording.output.section", comment: "Output"), systemImage: "arrow.up.doc")
            } footer: {
                if store.settings.output.copyToClipboard {
                    Text(String(
                        localized: "recording.output.copy_to_clipboard.footer",
                        comment: "Can paste immediately"
                    ))
                    .foregroundStyle(.secondary)
                }
            }

            // 無音検出セクション
            Section {
                Toggle(
                    String(localized: "recording.silence.auto_stop", comment: "Auto-stop on Silence"),
                    isOn: Binding(
                        get: { store.settings.recording.silenceDetectionEnabled },
                        set: { enabled in
                            var recording = store.settings.recording
                            recording.silenceDetectionEnabled = enabled
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                )
                .help(String(localized: "recording.silence.auto_stop.help", comment: "Auto stops when silent"))
                .accessibilityLabel(String(localized: "recording.silence.auto_stop", comment: "Auto-stop on Silence"))
                .accessibilityHint(String(
                    localized: "recording.silence.auto_stop.help",
                    comment: "Auto stops when silent"
                ))

                if store.settings.recording.silenceDetectionEnabled {
                    HStack {
                        Text(String(localized: "recording.silence.duration", comment: "Silence Duration"))
                        Spacer()
                        TextField(
                            String(localized: "recording.silence.duration.placeholder", comment: "seconds"),
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
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(String(
                            localized: "recording.silence.duration",
                            comment: "Silence Duration"
                        ))
                        .accessibilityHint(String(
                            localized: "recording.silence.duration.help",
                            comment: "Enter duration"
                        ))
                        Text(String(localized: "recording.silence.duration.placeholder", comment: "seconds"))
                    }

                    HStack {
                        Text(String(localized: "recording.silence.threshold", comment: "Silence Threshold"))
                        Spacer()
                        Text("\(Int(store.settings.recording.silenceThreshold)) dB")
                            .foregroundColor(.secondary)
                            .accessibilityLabel(
                                String(
                                    localized: "recording.silence.threshold.label",
                                    defaultValue:
                                    "Silence threshold: \(Int(store.settings.recording.silenceThreshold)) decibels",
                                    comment: "Threshold with value"
                                )
                            )
                    }
                }
            } header: {
                Text(String(localized: "recording.silence.section", comment: "Silence Detection"))
            } footer: {
                if store.settings.recording.silenceDetectionEnabled {
                    Text(String(localized: "recording.silence.footer", comment: "Stops when below threshold"))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
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
    .frame(width: 500, height: 400)
}
