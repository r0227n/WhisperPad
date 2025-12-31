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
