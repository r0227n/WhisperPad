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
            // MARK: - 録音セクション

            Section {
                Picker(
                    "入力デバイス",
                    selection: Binding(
                        get: { store.settings.recording.inputDeviceID },
                        set: { newValue in
                            var recording = store.settings.recording
                            recording.inputDeviceID = newValue
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                ) {
                    Text("システムデフォルト").tag(nil as String?)
                    ForEach(store.availableInputDevices) { device in
                        Text(device.name).tag(device.id as String?)
                    }
                }
                .help("録音に使用するマイクを選択します")
                .accessibilityLabel("入力デバイス")
                .accessibilityHint("録音に使用するマイクを選択します")
            } header: {
                Label("録音", systemImage: "waveform.circle")
            } footer: {
                Text("マイク入力を選択します。システムデフォルトを使用する場合は「システムデフォルト」を選択してください")
                    .foregroundStyle(.secondary)
            }

            // MARK: - 出力セクション

            Section {
                SettingRowWithIcon(
                    icon: "doc.on.clipboard",
                    iconColor: .blue,
                    title: "クリップボードにコピー",
                    isOn: Binding(
                        get: { store.settings.output.copyToClipboard },
                        set: { newValue in
                            var output = store.settings.output
                            output.copyToClipboard = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .help("文字起こし結果をクリップボードにコピーします")
                .accessibilityLabel("クリップボードにコピー")
                .accessibilityHint("オンにすると文字起こし結果をクリップボードにコピーします")

                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 20, alignment: .center)

                    Text("ファイルに保存")

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
                    .accessibilityLabel("ファイルに保存")

                    if store.settings.output.isEnabled {
                        HoverPopoverButton(label: "設定", icon: "folder.badge.gearshape") {
                            FileOutputDetailsPopover(store: store)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("ファイルに保存")
                .accessibilityHint("文字起こし結果をファイルに保存します")
            } header: {
                Label("出力", systemImage: "arrow.up.doc")
            } footer: {
                if store.settings.output.copyToClipboard {
                    Text("文字起こし完了後、すぐに他のアプリにペーストできます")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 無音検出セクション

            Section {
                SettingRowWithIcon(
                    icon: "mic.slash",
                    iconColor: .purple,
                    title: "無音検出で自動停止",
                    isOn: Binding(
                        get: { store.settings.recording.silenceDetectionEnabled },
                        set: { enabled in
                            var recording = store.settings.recording
                            recording.silenceDetectionEnabled = enabled
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                )
                .help("一定時間無音が続くと録音を自動停止します")
                .accessibilityLabel("無音検出で自動停止")
                .accessibilityHint("一定時間無音が続くと録音を自動停止します")

                if store.settings.recording.silenceDetectionEnabled {
                    HStack {
                        Text("無音判定時間")
                        Spacer()
                        TextField(
                            "秒",
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
                        .accessibilityLabel("無音判定時間")
                        .accessibilityHint("無音判定時間を秒単位で入力します")
                        Text("秒")
                    }

                    HStack {
                        Text("無音判定しきい値")
                        Spacer()
                        Text("\(Int(store.settings.recording.silenceThreshold)) dB")
                            .foregroundColor(.secondary)
                            .accessibilityLabel("無音判定しきい値: \(Int(store.settings.recording.silenceThreshold)) デシベル")
                    }
                }
            } header: {
                Label("無音検出", systemImage: "waveform.path.badge.minus")
            } footer: {
                if store.settings.recording.silenceDetectionEnabled {
                    Text("指定した時間、音声レベルがしきい値を下回ると録音を停止します")
                        .foregroundStyle(.secondary)
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
