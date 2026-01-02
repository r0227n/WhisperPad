//
//  FileOutputDetailsPopover.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import SwiftUI

/// File output details popover
///
/// Settings screen for customizing file save location and file format
struct FileOutputDetailsPopover: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text(L10n.get(.fileOutputTitle))
                    .font(.headline)
            }

            Divider()

            // Settings fields
            VStack(alignment: .leading, spacing: 12) {
                // Save location
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.fileOutputSaveLocation))
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

                        Button(L10n.get(.fileOutputChange)) {
                            selectOutputDirectory()
                        }
                        .accessibilityLabel(L10n.get(.fileOutputChangeSaveLocation))
                    }
                }

                // File name format
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.fileOutputFileNameFormat))
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
                        Text(L10n.get(.fileOutputDateTimeFormat))
                            .tag(FileOutputSettings.FileNameFormat.dateTime)
                        Text(L10n.get(.fileOutputTimestampFormat))
                            .tag(FileOutputSettings.FileNameFormat.timestamp)
                        Text(L10n.get(.fileOutputSequentialFormat))
                            .tag(FileOutputSettings.FileNameFormat.sequential)
                    }
                    .labelsHidden()
                    .accessibilityLabel(L10n.get(.fileOutputFileNameFormat))
                }

                // File format
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.get(.fileOutputFileFormat))
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
                    .accessibilityLabel(L10n.get(.fileOutputFileFormat))
                }

                // Metadata
                Toggle(
                    L10n.get(.fileOutputIncludeMetadata),
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
                .accessibilityLabel(L10n.get(.fileOutputIncludeMetadata))
                .accessibilityHint(L10n.get(.fileOutputMetadataDescription))
            }

            Divider()

            // Footer description
            Text(L10n.get(.fileOutputDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Select output directory
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = L10n.get(.fileOutputSelectFolder)
        panel.prompt = L10n.get(.fileOutputSelect)

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
