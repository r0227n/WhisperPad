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
    @Bindable var store: StoreOf<RecordingSettingsFeature>

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 16) {
                // セクションヘッダー
                SettingSectionHeader(
                    icon: "arrow.up.doc",
                    iconColor: .green,
                    title: "recording.output.title"
                )

                // クリップボードにコピー
                VStack(alignment: .leading, spacing: 8) {
                    SettingRowWithIcon(
                        icon: "doc.on.clipboard",
                        iconColor: .blue,
                        title: "recording.output.copy_to_clipboard",
                        isOn: Binding(
                            get: { store.output.copyToClipboard },
                            set: { newValue in
                                var output = store.output
                                output.copyToClipboard = newValue
                                store.send(.updateOutputSettings(output))
                            }
                        )
                    )

                    if store.output.copyToClipboard {
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
                                get: { store.output.isEnabled },
                                set: { newValue in
                                    var output = store.output
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

                    if store.output.isEnabled {
                        HStack(alignment: .top, spacing: 12) {
                            // Left: Path display
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(store.output.outputDirectory.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .padding(.leading, 32)

                            Spacer()

                            // Right: Configure button
                            HoverPopoverButton(
                                label: "recording.output.configure",
                                icon: "folder.badge.gearshape"
                            ) {
                                FileOutputDetailsPopoverForRecording(store: store)
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

/// RecordingSettingsFeature用のFileOutputDetailsPopover
///
/// 親のSettingsFeature用と分離するためのラッパービュー
struct FileOutputDetailsPopoverForRecording: View {
    @Bindable var store: StoreOf<RecordingSettingsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            PopoverHeaderView(
                icon: "folder.badge.gearshape",
                iconColor: .blue,
                title: "file_output_details.title"
            )

            Divider()

            // Output directory
            VStack(alignment: .leading, spacing: 8) {
                Text("file_output_details.output_directory", comment: "Output Directory")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text(store.output.outputDirectory.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button {
                        selectOutputDirectory()
                    } label: {
                        Text("file_output_details.change", comment: "Change")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // File naming pattern
            VStack(alignment: .leading, spacing: 8) {
                Text("file_output_details.naming_pattern", comment: "Naming Pattern")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker(
                    "",
                    selection: Binding(
                        get: { store.output.fileNameFormat },
                        set: { newValue in
                            var output = store.output
                            output.fileNameFormat = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                ) {
                    ForEach(FileOutputSettings.FileNameFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .labelsHidden()
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = String(localized: "file_output_details.select_folder", comment: "Select folder")
        panel.prompt = String(localized: "file_output_details.select", comment: "Select")

        if panel.runModal() == .OK, let url = panel.url {
            var output = store.output
            output.outputDirectory = url
            store.send(.updateOutputSettings(output))
        }
    }
}

// MARK: - Preview

#Preview("Both Enabled") {
    OutputSettingsSection(
        store: Store(initialState: RecordingSettingsFeature.State()) {
            RecordingSettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Only Clipboard") {
    OutputSettingsSection(
        store: Store(
            initialState: RecordingSettingsFeature.State(
                output: {
                    var settings = FileOutputSettings.default
                    settings.isEnabled = false
                    settings.copyToClipboard = true
                    return settings
                }()
            )
        ) {
            RecordingSettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Only File") {
    OutputSettingsSection(
        store: Store(
            initialState: RecordingSettingsFeature.State(
                output: {
                    var settings = FileOutputSettings.default
                    settings.isEnabled = true
                    settings.copyToClipboard = false
                    return settings
                }()
            )
        ) {
            RecordingSettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}

#Preview("Both Disabled") {
    OutputSettingsSection(
        store: Store(
            initialState: RecordingSettingsFeature.State(
                output: {
                    var settings = FileOutputSettings.default
                    settings.isEnabled = false
                    settings.copyToClipboard = false
                    return settings
                }()
            )
        ) {
            RecordingSettingsFeature()
        }
    )
    .padding()
    .frame(width: 500)
}
