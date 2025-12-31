//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音設定タブ
///
/// 音声録音の設定を行います。
/// 入力デバイス、録音時間、無音検出などを設定できます。
struct RecordingSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // 入力デバイスセクション
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
                    // 将来的に利用可能なデバイス一覧をここに表示
                }
                .help("録音に使用するマイクを選択します")
            } header: {
                Text("入力デバイス")
            }

            // 録音時間セクション
            Section {
                Toggle(
                    "無制限",
                    isOn: Binding(
                        get: { store.settings.recording.maxDuration == nil },
                        set: { isUnlimited in
                            var recording = store.settings.recording
                            recording.maxDuration = isUnlimited ? nil : 60.0
                            store.send(.updateRecordingSettings(recording))
                        }
                    )
                )
                .help("録音時間の制限を設けない")

                if let maxDuration = store.settings.recording.maxDuration {
                    HStack {
                        Text("最大録音時間")
                        Spacer()
                        TextField(
                            "秒",
                            value: Binding(
                                get: { Int(maxDuration) },
                                set: { newValue in
                                    var recording = store.settings.recording
                                    recording.maxDuration = TimeInterval(newValue)
                                    store.send(.updateRecordingSettings(recording))
                                }
                            ),
                            format: .number
                        )
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        Text("秒")
                    }
                }
            } header: {
                Text("録音時間")
            }

            // 無音検出セクション
            Section {
                Toggle(
                    "無音検出で自動停止",
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
                        Text("秒")
                    }

                    HStack {
                        Text("無音判定しきい値")
                        Spacer()
                        Text("\(Int(store.settings.recording.silenceThreshold)) dB")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("無音検出")
            } footer: {
                if store.settings.recording.silenceDetectionEnabled {
                    Text("指定した時間、音声レベルがしきい値を下回ると録音を停止します")
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
