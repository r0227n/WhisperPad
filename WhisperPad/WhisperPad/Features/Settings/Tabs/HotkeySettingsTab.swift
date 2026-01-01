//
//  HotkeySettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ホットキー設定タブ
///
/// グローバルホットキーの設定を行います。
/// 録音、ペースト、設定を開くホットキーを変更できます。
struct HotkeySettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // 録音セクション
            Section {
                HotkeyRecorderView(
                    label: "録音開始/停止",
                    keyCombo: Binding(
                        get: { store.settings.hotKey.recordingHotKey },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.recordingHotKey = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    ),
                    isRecording: store.recordingHotkeyType == .recording,
                    onStartRecording: { store.send(.startRecordingHotkey(.recording)) },
                    onStopRecording: { store.send(.stopRecordingHotkey) },
                    onClear: {
                        var hotKey = store.settings.hotKey
                        hotKey.recordingHotKey = .recordingDefault
                        store.send(.updateHotKeySettings(hotKey))
                    }
                )
                .help("録音を開始または停止するホットキー")

                Picker(
                    "録音モード",
                    selection: Binding(
                        get: { store.settings.hotKey.recordingMode },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.recordingMode = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    )
                ) {
                    ForEach(HotKeySettings.RecordingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("トグル: 1回押しで開始/停止、プッシュ・トゥ・トーク: 押している間のみ録音")

                HotkeyRecorderView(
                    label: "録音開始/終了",
                    keyCombo: Binding(
                        get: { store.settings.hotKey.recordingToggleHotKey },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.recordingToggleHotKey = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    ),
                    isRecording: store.recordingHotkeyType == .recordingToggle,
                    onStartRecording: { store.send(.startRecordingHotkey(.recordingToggle)) },
                    onStopRecording: { store.send(.stopRecordingHotkey) },
                    onClear: {
                        var hotKey = store.settings.hotKey
                        hotKey.recordingToggleHotKey = .recordingToggleDefault
                        store.send(.updateHotKeySettings(hotKey))
                    }
                )
                .help("録音を開始または終了するホットキー（トグル動作）")

                HotkeyRecorderView(
                    label: "録音一時停止/再開",
                    keyCombo: Binding(
                        get: { store.settings.hotKey.recordingPauseHotKey },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.recordingPauseHotKey = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    ),
                    isRecording: store.recordingHotkeyType == .recordingPause,
                    onStartRecording: { store.send(.startRecordingHotkey(.recordingPause)) },
                    onStopRecording: { store.send(.stopRecordingHotkey) },
                    onClear: {
                        var hotKey = store.settings.hotKey
                        hotKey.recordingPauseHotKey = .recordingPauseDefault
                        store.send(.updateHotKeySettings(hotKey))
                    }
                )
                .help("録音を一時停止または再開するホットキー")
            } header: {
                Text("録音")
            }

            // アプリセクション
            Section {
                HotkeyRecorderView(
                    label: "設定を開く",
                    keyCombo: Binding(
                        get: { store.settings.hotKey.openSettingsHotKey },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.openSettingsHotKey = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    ),
                    isRecording: store.recordingHotkeyType == .openSettings,
                    onStartRecording: { store.send(.startRecordingHotkey(.openSettings)) },
                    onStopRecording: { store.send(.stopRecordingHotkey) },
                    onClear: {
                        var hotKey = store.settings.hotKey
                        hotKey.openSettingsHotKey = .openSettingsDefault
                        store.send(.updateHotKeySettings(hotKey))
                    }
                )
                .help("設定画面を開くホットキー")
            } header: {
                Text("アプリ")
            }

            // キャンセルセクション
            Section {
                HotkeyRecorderView(
                    label: "録音キャンセル",
                    keyCombo: Binding(
                        get: { store.settings.hotKey.cancelHotKey },
                        set: { newValue in
                            var hotKey = store.settings.hotKey
                            hotKey.cancelHotKey = newValue
                            store.send(.updateHotKeySettings(hotKey))
                        }
                    ),
                    isRecording: store.recordingHotkeyType == .cancel,
                    onStartRecording: { store.send(.startRecordingHotkey(.cancel)) },
                    onStopRecording: { store.send(.stopRecordingHotkey) },
                    onClear: {
                        var hotKey = store.settings.hotKey
                        hotKey.cancelHotKey = .cancelDefault
                        store.send(.updateHotKeySettings(hotKey))
                    }
                )
                .help("録音をキャンセルするホットキー")
            } header: {
                Text("キャンセル")
            }

            // 競合警告セクション
            if let conflict = store.hotkeyConflict {
                Section {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            // 注意セクション
            Section {
                Label(
                    "他のアプリと競合する場合は変更してください",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundColor(.secondary)
                .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    HotkeySettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 500, height: 400)
}
