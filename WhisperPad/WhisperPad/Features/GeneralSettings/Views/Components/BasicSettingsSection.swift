//
//  BasicSettingsSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 基本設定セクション
///
/// 言語、ログイン時自動起動、キャンセル確認ダイアログの設定を行います。
struct BasicSettingsSection: View {
    @Bindable var store: StoreOf<GeneralSettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Section Header

                SettingSectionHeader(
                    icon: "gearshape.circle.fill",
                    iconColor: .gray,
                    title: "settings.general.basic"
                )

                // MARK: - Language Picker

                SettingRowWithIcon(
                    icon: "globe",
                    iconColor: .blue,
                    title: "settings.general.language.title"
                ) {
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.general.preferredLocale },
                            set: { newValue in
                                var general = store.general
                                general.preferredLocale = newValue
                                store.send(.updateGeneralSettings(general))
                            }
                        )
                    ) {
                        ForEach(AppLocale.allCases, id: \.self) { locale in
                            Text(locale.localizedKey).tag(locale)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }

                Text("settings.general.language.footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)

                Divider()

                // MARK: - Launch at Login

                SettingRowWithIcon(
                    icon: "power",
                    iconColor: .green,
                    title: "settings.general.launch_at_login",
                    isOn: Binding(
                        get: { store.general.launchAtLogin },
                        set: { newValue in
                            var general = store.general
                            general.launchAtLogin = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(
                    String(
                        localized: "settings.general.launch_at_login.help",
                        comment: "Launch at login help"
                    )
                )
                .accessibilityLabel(
                    String(
                        localized: "settings.general.launch_at_login",
                        comment: "Launch at Login"
                    )
                )
                .accessibilityHint(
                    String(
                        localized: "settings.general.launch_at_login.help",
                        comment: "Launch at login help"
                    )
                )

                // MARK: - Cancel Confirmation

                SettingRowWithIcon(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "settings.general.cancel_confirmation",
                    isOn: Binding(
                        get: { store.general.showCancelConfirmation },
                        set: { newValue in
                            var general = store.general
                            general.showCancelConfirmation = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help(
                    String(
                        localized: "settings.general.cancel_confirmation.help",
                        comment: "Cancel confirmation help"
                    )
                )
                .accessibilityLabel(
                    String(
                        localized: "settings.general.cancel_confirmation",
                        comment: "Show cancel confirmation"
                    )
                )
                .accessibilityHint(
                    String(
                        localized: "settings.general.cancel_confirmation.help",
                        comment: "Cancel confirmation help"
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BasicSettingsSection(
        store: Store(initialState: GeneralSettingsFeature.State()) {
            GeneralSettingsFeature()
        }
    )
    .padding()
    .frame(width: 520)
}
