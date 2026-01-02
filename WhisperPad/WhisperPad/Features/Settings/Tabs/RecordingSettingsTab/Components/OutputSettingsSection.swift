//
//  OutputSettingsSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 出力設定セクション
///
/// 文字起こし結果の出力設定（クリップボード、ファイル保存）を表示するコンポーネント。
/// 既存の機能を維持しながら、視覚的に改善されたUIを提供します。
struct OutputSettingsSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // セクションヘッダー
                SettingSectionHeader(
                    icon: "arrow.up.doc",
                    iconColor: .green,
                    title: "Output Settings",
                    helpText: "Choose where to save your transcription results"
                )

                // クリップボードにコピー
                VStack(alignment: .leading, spacing: 8) {
                    SettingRowWithIcon(
                        icon: "doc.on.clipboard",
                        iconColor: .blue,
                        title: "Copy to Clipboard",
                        isOn: Binding(
                            get: { store.settings.output.copyToClipboard },
                            set: { newValue in
                                var output = store.settings.output
                                output.copyToClipboard = newValue
                                store.send(.updateOutputSettings(output))
                            }
                        )
                    )

                    if store.settings.output.copyToClipboard {
                        Text("Transcription results will be copied to clipboard automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                    }
                }

                Divider()

                // ファイルに保存
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.cyan)
                            .frame(width: 20, alignment: .center)

                        Text("Save to File")

                        Spacer()

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { store.settings.output.isEnabled },
                                set: { newValue in
                                    var output = store.settings.output
                                    output.isEnabled = newValue
                                    store.send(.updateOutputSettings(output))
                                }
                            )
                        )
                        .labelsHidden()
                        .accessibilityLabel("Save to File")

                        if store.settings.output.isEnabled {
                            HoverPopoverButton(
                                label: "Configure",
                                icon: "folder.badge.gearshape"
                            ) {
                                FileOutputDetailsPopover(store: store)
                            }
                        }
                    }

                    if store.settings.output.isEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(store.settings.output.directory?.path ?? "Not selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .padding(.leading, 32)

                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Format: \(store.settings.output.format.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 32)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Save to File")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Output settings")
    }
}

// MARK: - Preview

#Preview("Both Enabled") {
    OutputSettingsSection(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Only Clipboard") {
    OutputSettingsSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    output: FileOutputSettings(
                        isEnabled: false,
                        copyToClipboard: true
                    )
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Only File") {
    OutputSettingsSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    output: FileOutputSettings(
                        isEnabled: true,
                        copyToClipboard: false
                    )
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Both Disabled") {
    OutputSettingsSection(
        store: Store(
            initialState: SettingsFeature.State(
                settings: AppSettings(
                    output: FileOutputSettings(
                        isEnabled: false,
                        copyToClipboard: false
                    )
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}
