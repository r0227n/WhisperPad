//
//  NotificationPerformanceSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 通知・パフォーマンス設定セクション
///
/// 完了通知、サウンド再生、メッセージカスタマイズ、WhisperKit自動アンロードの設定を行います。
struct NotificationPerformanceSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Section Header

                SettingSectionHeader(
                    icon: "bell.badge.fill",
                    iconColor: .orange,
                    title: "settings.general.notification"
                )

                // MARK: - Notification Settings

                VStack(alignment: .leading, spacing: 12) {
                    // Show Notification Toggle
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
                        String(
                            localized: "settings.general.show_notification",
                            comment: "Show Notifications"
                        )
                    )
                    .accessibilityHint(
                        String(
                            localized: "settings.general.show_notification.help",
                            comment: "Show notification help"
                        )
                    )

                    // Play Sound Toggle
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
                    .help(
                        String(
                            localized: "settings.general.play_sound.help",
                            comment: "Play sound help"
                        )
                    )
                    .accessibilityLabel(
                        String(
                            localized: "settings.general.play_sound",
                            comment: "Play Sound"
                        )
                    )
                    .accessibilityHint(
                        String(
                            localized: "settings.general.play_sound.help",
                            comment: "Play sound help"
                        )
                    )

                    // Message Customization
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
                }

                Text("settings.general.notification.footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)

                Divider()

                // MARK: - Performance Settings

                VStack(alignment: .leading, spacing: 12) {
                    // WhisperKit Auto-unload Toggle
                    SettingRowWithIcon(
                        icon: "memorychip",
                        iconColor: .indigo,
                        title: "settings.general.whisperkit_auto_unload",
                        isOn: Binding(
                            get: { store.settings.general.whisperKitIdleTimeoutEnabled },
                            set: { newValue in
                                var general = store.settings.general
                                general.whisperKitIdleTimeoutEnabled = newValue
                                store.send(.updateGeneralSettings(general))
                            }
                        )
                    )
                    .help(
                        String(
                            localized: "settings.general.whisperkit_auto_unload.help",
                            comment: "Auto-unload WhisperKit help"
                        )
                    )
                    .accessibilityLabel(
                        String(
                            localized: "settings.general.whisperkit_auto_unload",
                            comment: "Auto-release memory when idle"
                        )
                    )
                    .accessibilityHint(
                        String(
                            localized: "settings.general.whisperkit_auto_unload.help",
                            comment: "Auto-unload WhisperKit help"
                        )
                    )

                    // Timeout Slider (conditional)
                    if store.settings.general.whisperKitIdleTimeoutEnabled {
                        HStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.teal)
                                .frame(width: 20, alignment: .center)

                            Text("settings.general.whisperkit_timeout")

                            Spacer()

                            Slider(
                                value: Binding(
                                    get: {
                                        Double(store.settings.general.whisperKitIdleTimeoutMinutes)
                                    },
                                    set: { newValue in
                                        var general = store.settings.general
                                        general.whisperKitIdleTimeoutMinutes = Int(newValue)
                                        store.send(.updateGeneralSettings(general))
                                    }
                                ),
                                in: 5 ... 60,
                                step: 5
                            )
                            .frame(width: 150)

                            Text("\(store.settings.general.whisperKitIdleTimeoutMinutes) min")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }

                Text("settings.general.performance.footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }
        }
        .animation(.default, value: store.settings.general.whisperKitIdleTimeoutEnabled)
    }
}

// MARK: - Preview

#Preview {
    NotificationPerformanceSection(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 520)
}
