//
//  FileOutputDetailsPopover.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import SwiftUI

/// ファイル出力詳細設定ポップオーバー
///
/// ファイル保存先やファイル形式をカスタマイズするための設定画面
struct FileOutputDetailsPopover: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text("file_output.title", comment: "File Output Settings")
                    .font(.headline)
            }

            Divider()

            // 設定フィールド
            VStack(alignment: .leading, spacing: 12) {
                // 保存先
                VStack(alignment: .leading, spacing: 4) {
                    Text("file_output.location", comment: "Location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(store.settings.output.outputDirectory.path)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .textBackgroundColor))
                            )

                        Button(String(localized: "common.change", comment: "Change...")) {
                            selectOutputDirectory()
                        }
                        .accessibilityLabel(
                            String(localized: "file_output.change_location", comment: "Change location")
                        )
                    }
                }

                // ファイル名形式
                VStack(alignment: .leading, spacing: 4) {
                    Text("file_output.filename_format", comment: "Filename Format")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.settings.output.fileNameFormat },
                            set: { newValue in
                                var output = store.settings.output
                                output.fileNameFormat = newValue
                                store.send(.updateOutputSettings(output))
                            }
                        )
                    ) {
                        Text("file_output.filename_format.datetime", comment: "Date Time (WhisperPad_20241201_143052)")
                            .tag(FileOutputSettings.FileNameFormat.dateTime)
                        Text("file_output.filename_format.timestamp", comment: "Timestamp (WhisperPad_1701415852)")
                            .tag(FileOutputSettings.FileNameFormat.timestamp)
                        Text("file_output.filename_format.sequential", comment: "Sequential (WhisperPad_001)")
                            .tag(FileOutputSettings.FileNameFormat.sequential)
                    }
                    .labelsHidden()
                    .accessibilityLabel(
                        String(localized: "file_output.filename_format", comment: "Filename Format")
                    )
                }

                // ファイル形式
                VStack(alignment: .leading, spacing: 4) {
                    Text("file_output.file_format", comment: "File Format")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.settings.output.fileExtension },
                            set: { newValue in
                                var output = store.settings.output
                                output.fileExtension = newValue
                                store.send(.updateOutputSettings(output))
                            }
                        )
                    ) {
                        ForEach(FileOutputSettings.FileExtension.allCases, id: \.self) { ext in
                            Text(".\(ext.rawValue)").tag(ext)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityLabel(
                        String(localized: "file_output.file_format", comment: "File Format")
                    )
                }

                // メタデータ
                Toggle(
                    String(localized: "file_output.include_metadata", comment: "Include Metadata"),
                    isOn: Binding(
                        get: { store.settings.output.includeMetadata },
                        set: { newValue in
                            var output = store.settings.output
                            output.includeMetadata = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .font(.subheadline)
                .accessibilityLabel(
                    String(localized: "file_output.include_metadata", comment: "Include Metadata")
                )
                .accessibilityHint(
                    String(
                        localized: "file_output.include_metadata.help",
                        comment: "Includes creation date and app info in file"
                    )
                )
            }

            Divider()

            // フッター説明
            Text("file_output.footer", comment: "Saves transcription results as text files")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }

    /// 出力ディレクトリを選択
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = String(
            localized: "file_output.select_folder.message",
            comment: "Please select the folder to save files"
        )
        panel.prompt = String(localized: "file_output.select_folder.prompt", comment: "Select")

        if panel.runModal() == .OK, let url = panel.url {
            var output = store.settings.output
            output.outputDirectory = url
            store.send(.updateOutputSettings(output))
        }
    }
}

// MARK: - Preview

#Preview {
    FileOutputDetailsPopover(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .padding()
    .frame(width: 360)
}
