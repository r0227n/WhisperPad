//
//  GeneralSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// General settings tab
///
/// Configures basic application behavior.
/// Consists of three sections: Language, Behavior, Notification
struct GeneralSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        Form {
            // MARK: - Language Section

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 20, alignment: .center)

                    Text(L10n.get(.generalLanguage))

                    Spacer()

                    Picker("", selection: Binding(
                        get: { store.settings.general.appLanguage },
                        set: { newValue in
                            var general = store.settings.general
                            general.appLanguage = newValue
                            store.send(.updateGeneralSettings(general))
                            LocalizationManager.shared.setLanguage(newValue)
                        }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            } header: {
                Label(L10n.get(.generalLanguage), systemImage: "globe")
            } footer: {
                Text(L10n.get(.generalLanguageDescription))
                    .foregroundStyle(.secondary)
            }

            // MARK: - Behavior Section

            Section {
                SettingRowWithIcon(
                    icon: "power",
                    iconColor: .green,
                    title: L10n.get(.generalLaunchAtLogin),
                    isOn: Binding(
                        get: { store.settings.general.launchAtLogin },
                        set: { newValue in
                            var general = store.settings.general
                            general.launchAtLogin = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(L10n.get(.generalLaunchAtLoginDescription))
                .accessibilityLabel(L10n.get(.generalLaunchAtLogin))
                .accessibilityHint(L10n.get(.generalLaunchAtLoginDescription))
            } header: {
                Label(L10n.get(.generalBehavior), systemImage: "gearshape.2")
            }

            // MARK: - Notification Section

            Section {
                SettingRowWithIcon(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: L10n.get(.generalShowNotification),
                    isOn: Binding(
                        get: { store.settings.general.showNotificationOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.showNotificationOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(L10n.get(.generalShowNotificationDescription))
                .accessibilityLabel(L10n.get(.generalShowNotification))
                .accessibilityHint(L10n.get(.generalShowNotificationDescription))

                SettingRowWithIcon(
                    icon: "speaker.wave.2.fill",
                    iconColor: .pink,
                    title: L10n.get(.generalPlaySound),
                    isOn: Binding(
                        get: { store.settings.general.playSoundOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.playSoundOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(L10n.get(.generalPlaySoundDescription))
                .accessibilityLabel(L10n.get(.generalPlaySound))
                .accessibilityHint(L10n.get(.generalPlaySoundDescription))

                HStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.purple)
                        .frame(width: 20, alignment: .center)

                    Text(L10n.get(.generalNotificationSettings))

                    Spacer()

                    HoverPopoverButton(label: L10n.get(.generalCustomize), icon: "slider.horizontal.3") {
                        NotificationDetailsPopover(store: store)
                    }
                }
            } header: {
                Label(L10n.get(.generalNotification), systemImage: "bell.badge")
            } footer: {
                Text(L10n.get(.generalNotificationSectionDescription))
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
