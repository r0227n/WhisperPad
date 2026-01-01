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
                Text("ファイル出力設定")
                    .font(.headline)
            }

            Divider()

            // 設定フィールド
            VStack(alignment: .leading, spacing: 12) {
                // 保存先
                VStack(alignment: .leading, spacing: 4) {
                    Text("保存先")
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

                        Button("変更...") {
                            selectOutputDirectory()
                        }
                        .accessibilityLabel("保存先を変更")
                    }
                }

                // ファイル名形式
                VStack(alignment: .leading, spacing: 4) {
                    Text("ファイル名形式")
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
                        Text("日時 (WhisperPad_20241201_143052)")
                            .tag(FileOutputSettings.FileNameFormat.dateTime)
                        Text("タイムスタンプ (WhisperPad_1701415852)")
                            .tag(FileOutputSettings.FileNameFormat.timestamp)
                        Text("連番 (WhisperPad_001)")
                            .tag(FileOutputSettings.FileNameFormat.sequential)
                    }
                    .labelsHidden()
                    .accessibilityLabel("ファイル名形式")
                }

                // ファイル形式
                VStack(alignment: .leading, spacing: 4) {
                    Text("ファイル形式")
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
                    .accessibilityLabel("ファイル形式")
                }

                // メタデータ
                Toggle(
                    "メタデータを含める",
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
                .accessibilityLabel("メタデータを含める")
                .accessibilityHint("ファイルに作成日時やアプリ情報を含めます")
            }

            Divider()

            // フッター説明
            Text("文字起こし結果をテキストファイルとして保存します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 出力ディレクトリを選択
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "ファイルの保存先フォルダを選択してください"
        panel.prompt = "選択"

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
