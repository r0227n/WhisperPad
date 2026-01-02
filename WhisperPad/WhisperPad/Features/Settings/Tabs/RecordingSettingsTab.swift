//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Recording settings tab
///
/// Configures audio recording settings.
/// Allows setting input device, output settings, silence detection, etc.
struct RecordingSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        Form {
            // Input device section
            Section {
                Picker(
                    L10n.get(.recordingInputDevice),
                    selection: Binding(
                        get: { store.settings.recording.inputDeviceID },
                        set: { newValue in
                            var recording = store.settings.recording
                            recording.inputDeviceID = newValue
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                ) {
                    Text(L10n.get(.recordingSystemDefault)).tag(nil as String?)
                    ForEach(store.availableInputDevices) { device in
                        Text(device.name).tag(device.id as String?)
                    }
                }
                .help(L10n.get(.recordingInputDeviceDescription))
                .accessibilityLabel(L10n.get(.recordingInputDevice))
                .accessibilityHint(L10n.get(.recordingInputDeviceDescription))
            } header: {
                Text(L10n.get(.recordingInputDevice))
            }

            // MARK: - Output Section

            Section {
                SettingRowWithIcon(
                    icon: "doc.on.clipboard",
                    iconColor: .blue,
                    title: L10n.get(.recordingCopyToClipboard),
                    isOn: Binding(
                        get: { store.settings.output.copyToClipboard },
                        set: { newValue in
                            var output = store.settings.output
                            output.copyToClipboard = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .help(L10n.get(.recordingCopyToClipboardDescription))
                .accessibilityLabel(L10n.get(.recordingCopyToClipboard))
                .accessibilityHint(L10n.get(.recordingCopyToClipboardToggleDescription))

                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 20, alignment: .center)

                    Text(L10n.get(.recordingSaveToFile))

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
                    .accessibilityLabel(L10n.get(.recordingSaveToFile))

                    if store.settings.output.isEnabled {
                        HoverPopoverButton(label: L10n.get(.recordingSettings), icon: "folder.badge.gearshape") {
                            FileOutputDetailsPopover(store: store)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L10n.get(.recordingSaveToFile))
                .accessibilityHint(L10n.get(.recordingCopyToClipboardDescription))
            } header: {
                Label(L10n.get(.recordingOutput), systemImage: "arrow.up.doc")
            } footer: {
                if store.settings.output.copyToClipboard {
                    Text(L10n.get(.recordingPasteDescription))
                        .foregroundStyle(.secondary)
                }
            }

            // Silence detection section
            Section {
                Toggle(
                    L10n.get(.recordingAutoStopOnSilence),
                    isOn: Binding(
                        get: { store.settings.recording.silenceDetectionEnabled },
                        set: { enabled in
                            var recording = store.settings.recording
                            recording.silenceDetectionEnabled = enabled
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                )
                .help(L10n.get(.recordingAutoStopDescription))
                .accessibilityLabel(L10n.get(.recordingAutoStopOnSilence))
                .accessibilityHint(L10n.get(.recordingAutoStopDescription))

                if store.settings.recording.silenceDetectionEnabled {
                    HStack {
                        Text(L10n.get(.recordingSilenceDuration))
                        Spacer()
                        TextField(
                            L10n.get(.recordingSeconds),
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
                        .accessibilityLabel(L10n.get(.recordingSilenceDuration))
                        Text(L10n.get(.recordingSeconds))
                    }

                    HStack {
                        Text(L10n.get(.recordingSilenceThreshold))
                        Spacer()
                        Text("\(Int(store.settings.recording.silenceThreshold)) \(L10n.get(.recordingDecibels))")
                            .foregroundColor(.secondary)
                            .accessibilityLabel(
                                "\(L10n.get(.recordingSilenceThreshold)): \(Int(store.settings.recording.silenceThreshold)) \(L10n.get(.recordingDecibels))"
                            )
                    }
                }
            } header: {
                Text(L10n.get(.recordingSilenceDetection))
            } footer: {
                if store.settings.recording.silenceDetectionEnabled {
                    Text(L10n.get(.recordingSilenceDescription))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
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
