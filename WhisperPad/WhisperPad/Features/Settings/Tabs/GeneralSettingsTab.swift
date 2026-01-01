//
//  GeneralSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 一般設定タブ
///
/// アプリケーションの基本的な動作設定を行います。
struct GeneralSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            Section {
                Toggle(
                    "ログイン時に起動",
                    isOn: Binding(
                        get: { store.settings.general.launchAtLogin },
                        set: { newValue in
                            var general = store.settings.general
                            general.launchAtLogin = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("macOS 起動時にアプリを自動的に起動します")
            } header: {
                Text("起動")
            }

            Section {
                Toggle(
                    "完了時に通知を表示",
                    isOn: Binding(
                        get: { store.settings.general.showNotificationOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.showNotificationOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("文字起こし完了時に通知センターに通知を表示します")

                Toggle(
                    "完了音を鳴らす",
                    isOn: Binding(
                        get: { store.settings.general.playSoundOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.playSoundOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("文字起こし完了時にサウンドを再生します")

                Divider()

                TextField(
                    "通知タイトル",
                    text: Binding(
                        get: { store.settings.general.notificationTitle },
                        set: { newValue in
                            var general = store.settings.general
                            general.notificationTitle = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .help("通知に表示されるタイトル")

                TextField(
                    "完了メッセージ（通常）",
                    text: Binding(
                        get: { store.settings.general.transcriptionCompleteMessage },
                        set: { newValue in
                            var general = store.settings.general
                            general.transcriptionCompleteMessage = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .help("通常録音完了時のメッセージ")

                TextField(
                    "完了メッセージ（リアルタイム）",
                    text: Binding(
                        get: { store.settings.general.streamingCompleteMessage },
                        set: { newValue in
                            var general = store.settings.general
                            general.streamingCompleteMessage = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .help("リアルタイム文字起こし完了時のメッセージ")

                Button("デフォルトに戻す") {
                    var general = store.settings.general
                    general.notificationTitle = "WhisperPad"
                    general.transcriptionCompleteMessage = "文字起こしが完了しました"
                    general.streamingCompleteMessage = "リアルタイム文字起こしが完了しました"
                    store.send(.updateGeneralSettings(general))
                }
                .buttonStyle(.link)
                .font(.caption)
            } header: {
                Text("通知")
            }

            Section {
                Picker(
                    "メニューバーアイコン",
                    selection: Binding(
                        get: { store.settings.general.menuBarIconStyle },
                        set: { newValue in
                            var general = store.settings.general
                            general.menuBarIconStyle = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                ) {
                    ForEach(GeneralSettings.MenuBarIconStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .help("メニューバーに表示するアイコンのスタイルを選択します")
            } header: {
                Text("外観")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 500, height: 400)
}
