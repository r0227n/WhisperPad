//
//  GeneralSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 一般設定タブ
///
/// アプリケーションの基本的な動作設定を行います。
/// 2つのセクションで構成: 動作、通知
struct GeneralSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // MARK: - 動作セクション

            Section {
                SettingRowWithIcon(
                    icon: "power",
                    iconColor: .green,
                    title: "ログイン時に起動",
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
                .accessibilityLabel("ログイン時に起動")
                .accessibilityHint("macOS 起動時にアプリを自動的に起動します")
            } header: {
                Label("動作", systemImage: "gearshape.2")
            }

            // MARK: - 通知セクション

            Section {
                SettingRowWithIcon(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "通知を表示",
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
                .accessibilityLabel("通知を表示")
                .accessibilityHint("文字起こし完了時に通知センターに通知を表示します")

                SettingRowWithIcon(
                    icon: "speaker.wave.2.fill",
                    iconColor: .pink,
                    title: "サウンドを再生",
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
                .accessibilityLabel("サウンドを再生")
                .accessibilityHint("文字起こし完了時にサウンドを再生します")

                HStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.purple)
                        .frame(width: 20, alignment: .center)

                    Text("メッセージ設定")

                    Spacer()

                    HoverPopoverButton(label: "カスタマイズ", icon: "slider.horizontal.3") {
                        NotificationDetailsPopover(store: store)
                    }
                }
            } header: {
                Label("通知", systemImage: "bell.badge")
            } footer: {
                Text("文字起こし完了時の通知とサウンドを設定します")
                    .foregroundStyle(.secondary)
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
    .frame(width: 520, height: 500)
}
