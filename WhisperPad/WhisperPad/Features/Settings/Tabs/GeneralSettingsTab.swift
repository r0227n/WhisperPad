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
            // MARK: - 言語セクション / Language Section

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 20, alignment: .center)

                    Text("settings.general.language.title", comment: "Language")

                    Spacer()

                    Picker("", selection: Binding(
                        get: { store.settings.general.preferredLocale },
                        set: { newValue in
                            var general = store.settings.general
                            general.preferredLocale = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )) {
                        ForEach(AppLocale.allCases, id: \.self) { locale in
                            Text(locale.localizedKey).tag(locale)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }
            } header: {
                Label("settings.general.language.section", systemImage: "globe")
            } footer: {
                Text("settings.general.language.footer")
                    .foregroundStyle(.secondary)
            }

            // MARK: - 動作セクション

            Section {
                SettingRowWithIcon(
                    icon: "power",
                    iconColor: .green,
                    title: "settings.general.launch_at_login",
                    isOn: Binding(
                        get: { store.settings.general.launchAtLogin },
                        set: { newValue in
                            var general = store.settings.general
                            general.launchAtLogin = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(
                    String(localized: "settings.general.launch_at_login.help", comment: "Launch at login help")
                )
                .accessibilityLabel(
                    String(localized: "settings.general.launch_at_login", comment: "Launch at Login")
                )
                .accessibilityHint(
                    String(localized: "settings.general.launch_at_login.help", comment: "Launch at login help")
                )
            } header: {
                Label("settings.general.behavior", systemImage: "gearshape.2")
            }

            // MARK: - 通知セクション

            Section {
                SettingRowWithIcon(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "settings.general.show_notification",
                    isOn: Binding(
                        get: { store.settings.general.showNotificationOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.showNotificationOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(
                    String(
                        localized: "settings.general.show_notification.help",
                        comment: "Show notification help"
                    )
                )
                .accessibilityLabel(
                    String(localized: "settings.general.show_notification", comment: "Show Notifications")
                )
                .accessibilityHint(
                    String(
                        localized: "settings.general.show_notification.help",
                        comment: "Show notification help"
                    )
                )

                SettingRowWithIcon(
                    icon: "speaker.wave.2.fill",
                    iconColor: .pink,
                    title: "settings.general.play_sound",
                    isOn: Binding(
                        get: { store.settings.general.playSoundOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.playSoundOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(String(localized: "settings.general.play_sound.help", comment: "Play sound help"))
                .accessibilityLabel(String(localized: "settings.general.play_sound", comment: "Play Sound"))
                .accessibilityHint(
                    String(localized: "settings.general.play_sound.help", comment: "Play sound help")
                )

                HStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.purple)
                        .frame(width: 20, alignment: .center)

                    Text("settings.general.notification.message", comment: "Message Settings")

                    Spacer()

                    HoverPopoverButton(
                        label: "settings.general.notification.message.customize",
                        icon: "slider.horizontal.3"
                    ) {
                        NotificationDetailsPopover(store: store)
                    }
                }
            } header: {
                Label("settings.general.notification", systemImage: "bell.badge")
            } footer: {
                Text("settings.general.notification.footer")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .environment(\.locale, store.settings.general.preferredLocale.locale)
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
