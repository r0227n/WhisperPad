//
//  RecordingSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音設定タブ
///
/// 音声録音の設定を行います。
/// 入力デバイス、無音検出などを設定できます。
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
                    ForEach(store.availableInputDevices) { device in
                        Text(device.name).tag(device.id as String?)
                    }
                }
                .help("録音に使用するマイクを選択します")
                .accessibilityLabel("入力デバイス")
                .accessibilityHint("録音に使用するマイクを選択します")
            } header: {
                Text("入力デバイス")
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
                Text("無音検出")
            } footer: {
                if store.settings.recording.silenceDetectionEnabled {
                    Text("指定した時間、音声レベルがしきい値を下回ると録音を停止します")
                }
            }

            // ストリーミング設定セクション
            Section {
                Toggle(
                    "リアルタイムプレビューを表示",
                    isOn: Binding(
                        get: { store.settings.streaming.showDecodingPreview },
                        set: { enabled in
                            var streaming = store.settings.streaming
                            streaming.showDecodingPreview = enabled
                            store.send(.updateStreamingSettings(streaming))
                        }
                    )
                )
                .help("リアルタイム文字起こし中にデコード中のテキストをプレビュー表示します")
                .accessibilityLabel("リアルタイムプレビューを表示")
                .accessibilityHint("リアルタイム文字起こし中にデコード中のテキストをプレビュー表示します")
            } header: {
                Text("ストリーミング")
            } footer: {
                Text("オンにすると、文字起こし中に認識途中のテキストが薄く表示されます")
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
