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
                    title: String(localized: "recording.output.title", comment: "Output Settings")
                )

                // クリップボードにコピー
                VStack(alignment: .leading, spacing: 8) {
                    SettingRowWithIcon(
                        icon: "doc.on.clipboard",
                        iconColor: .blue,
                        title: "recording.output.copy_to_clipboard",
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
                        Text(
                            "recording.output.copy_to_clipboard.help",
                            comment: "Transcription results will be copied to clipboard automatically"
                        )
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

                        Text("recording.output.save_to_file", comment: "Save to File")

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
                        .toggleStyle(.switch)
                        .accessibilityLabel(
                            String(localized: "recording.output.save_to_file", comment: "Save to File")
                        )
                    }

                    if store.settings.output.isEnabled {
                        HStack(alignment: .top, spacing: 12) {
                            // Left: Path and format display
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(store.settings.output.outputDirectory.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(
                                        String(
                                            format: String(localized: "recording.output.format", comment: "Format: %@"),
                                            store.settings.output.fileExtension.rawValue
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 32)

                            Spacer()

                            // Right: Configure button
                            HoverPopoverButton(
                                label: "recording.output.configure",
                                icon: "folder.badge.gearshape"
                            ) {
                                FileOutputDetailsPopover(store: store)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "recording.output.save_to_file", comment: "Save to File"))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "recording.output.accessibility", comment: "Output settings"))
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
                    output: {
                        var settings = FileOutputSettings.default
                        settings.isEnabled = false
                        settings.copyToClipboard = true
                        return settings
                    }()
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
                    output: {
                        var settings = FileOutputSettings.default
                        settings.isEnabled = true
                        settings.copyToClipboard = false
                        return settings
                    }()
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
                    output: {
                        var settings = FileOutputSettings.default
                        settings.isEnabled = false
                        settings.copyToClipboard = false
                        return settings
                    }()
                )
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}
