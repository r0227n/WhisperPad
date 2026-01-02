//
//  NotificationDetailsPopover.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Notification details popover
///
/// Settings screen for customizing notification title and messages
struct NotificationDetailsPopover: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.orange)
                Text(L10n.get(.notificationMessage))
                    .font(.headline)
            }

            Divider()

            // Settings fields
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.notificationTitle))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        L10n.get(.notificationTitlePlaceholder),
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
                    .accessibilityLabel(L10n.get(.notificationTitlePlaceholder))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.notificationCompletionMessage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        L10n.get(.notificationOnRegularCompletion),
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
                    .accessibilityLabel(L10n.get(.notificationCompletionMessage))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.notificationStreamingMessage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        L10n.get(.notificationOnStreamingCompletion),
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
                    .accessibilityLabel(L10n.get(.notificationStreamingMessage))
                }
            }

            Divider()

            // Reset to default button
            HStack {
                Spacer()
                Button(L10n.get(.notificationResetToDefault)) {
                    var general = store.settings.general
                    general.notificationTitle = L10n.get(.notificationDefaultTitle)
                    general.transcriptionCompleteMessage = L10n.get(.notificationDefaultMessage)
                    general.streamingCompleteMessage = L10n.get(.notificationDefaultStreamingMessage)
                    store.send(.updateGeneralSettings(general))
                }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityLabel(L10n.get(.notificationResetToDefault))
                .accessibilityHint(L10n.get(.notificationResetDescription))
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
