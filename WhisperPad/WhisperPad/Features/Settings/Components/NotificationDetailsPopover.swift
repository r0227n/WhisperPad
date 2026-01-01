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
                Text("通知メッセージ")
                    .font(.headline)
            }

            Divider()

            // 設定フィールド
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タイトル")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                    .accessibilityLabel("通知タイトル")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("完了メッセージ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        "通常録音完了時",
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
                    .accessibilityLabel("完了メッセージ")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("リアルタイム完了メッセージ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(
                        "リアルタイム文字起こし完了時",
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
                    .accessibilityLabel("リアルタイム完了メッセージ")
                }
            }

            Divider()

            // デフォルトに戻すボタン
            HStack {
                Spacer()
                Button("デフォルトに戻す") {
                    var general = store.settings.general
                    general.notificationTitle = "WhisperPad"
                    general.transcriptionCompleteMessage = "文字起こしが完了しました"
                    general.streamingCompleteMessage = "リアルタイム文字起こしが完了しました"
                    store.send(.updateGeneralSettings(general))
                }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityLabel("デフォルトに戻す")
                .accessibilityHint("通知設定を初期値に戻します")
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
