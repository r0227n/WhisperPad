//
//  NotificationDetailsPopover.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 通知詳細設定ポップオーバー
///
/// 通知のタイトルやメッセージをカスタマイズするための設定画面
struct NotificationDetailsPopover: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.orange)
                Text("notification.custom.title", comment: "Notification Message")
                    .font(.headline)
            }

            Divider()

            // 設定フィールド
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("notification.custom.notification_title", comment: "Title")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        String(
                            localized: "notification.custom.notification_title.placeholder",
                            comment: "Notification Title"
                        ),
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
                    .accessibilityLabel(
                        String(
                            localized: "notification.custom.notification_title",
                            comment: "Title"
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("notification.custom.complete_message", comment: "Complete Message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        String(
                            localized: "notification.custom.complete_message.placeholder",
                            comment: "When normal recording completes"
                        ),
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
                    .accessibilityLabel(
                        String(
                            localized: "notification.custom.complete_message",
                            comment: "Complete Message"
                        )
                    )
                }
            }

            Divider()

            // デフォルトに戻すボタン
            HStack {
                Spacer()
                Button(String(localized: "notification.custom.reset", comment: "Reset to Default")) {
                    var general = store.settings.general
                    general.notificationTitle = String(localized: "notification.default.title")
                    general.transcriptionCompleteMessage = String(
                        localized: "notification.transcription.complete.message"
                    )
                    store.send(.updateGeneralSettings(general))
                }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityLabel(
                    String(localized: "notification.custom.reset", comment: "Reset to Default")
                )
                .accessibilityHint(
                    String(
                        localized: "notification.custom.reset.help",
                        comment: "Resets notification settings to initial values"
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationDetailsPopover(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 320)
}
