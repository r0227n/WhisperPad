//
//  GeneralSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 一般設定タブ
///
/// アプリケーションの基本的な動作設定を行います。
struct GeneralSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            Section {
                Toggle(
                    "ログイン時に起動",
                    isOn: Binding(
                        get: { store.settings.general.launchAtLogin },
                        set: { newValue in
                            var general = store.settings.general
                            general.launchAtLogin = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("macOS 起動時にアプリを自動的に起動します")
                .accessibilityLabel("ログイン時に起動")
                .accessibilityHint("macOS 起動時にアプリを自動的に起動します")
            } header: {
                Text("起動")
            }

            Section {
                Toggle(
                    "完了時に通知を表示",
                    isOn: Binding(
                        get: { store.settings.general.showNotificationOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.showNotificationOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("文字起こし完了時に通知センターに通知を表示します")
                .accessibilityLabel("完了時に通知を表示")
                .accessibilityHint("文字起こし完了時に通知センターに通知を表示します")

                Toggle(
                    "完了音を鳴らす",
                    isOn: Binding(
                        get: { store.settings.general.playSoundOnComplete },
                        set: { newValue in
                            var general = store.settings.general
                            general.playSoundOnComplete = newValue
                            store.send(.updateGeneralSettings(general))
                        }
                    )
                )
                .help("文字起こし完了時にサウンドを再生します")
                .accessibilityLabel("完了音を鳴らす")
                .accessibilityHint("文字起こし完了時にサウンドを再生します")

                Divider()

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
                .help("通知に表示されるタイトル")
                .accessibilityLabel("通知タイトル")
                .accessibilityHint("通知に表示されるタイトルを入力します")

                TextField(
                    "完了メッセージ（通常）",
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
                .help("通常録音完了時のメッセージ")
                .accessibilityLabel("完了メッセージ（通常）")
                .accessibilityHint("通常録音完了時のメッセージを入力します")

                TextField(
                    "完了メッセージ（リアルタイム）",
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
                .help("リアルタイム文字起こし完了時のメッセージ")
                .accessibilityLabel("完了メッセージ（リアルタイム）")
                .accessibilityHint("リアルタイム文字起こし完了時のメッセージを入力します")

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
            } header: {
                Text("通知")
            }

            // MARK: - クリップボード

            Section {
                Toggle(
                    "クリップボードにコピー",
                    isOn: Binding(
                        get: { store.settings.output.copyToClipboard },
                        set: { newValue in
                            var output = store.settings.output
                            output.copyToClipboard = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .help("文字起こし結果をクリップボードにコピーします")
                .accessibilityLabel("クリップボードにコピー")
                .accessibilityHint("オンにすると文字起こし結果をクリップボードにコピーします")
            } header: {
                Text("クリップボード")
            } footer: {
                Text("文字起こし完了後、すぐに他のアプリにペーストできます")
                    .foregroundStyle(.secondary)
            }

            // MARK: - ファイル出力

            Section {
                Toggle(
                    "ファイルに保存",
                    isOn: Binding(
                        get: { store.settings.output.isEnabled },
                        set: { newValue in
                            var output = store.settings.output
                            output.isEnabled = newValue
                            store.send(.updateOutputSettings(output))
                        }
                    )
                )
                .accessibilityLabel("ファイルに保存")
                .accessibilityHint("文字起こし結果をファイルに保存します")

                if store.settings.output.isEnabled {
                    HStack {
                        Text("保存先")
                        Spacer()
                        Text(store.settings.output.outputDirectory.path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Button("変更...") {
                            selectOutputDirectory()
                        }
                        .accessibilityLabel("保存先を変更")
                        .accessibilityHint("ファイルの保存先フォルダを選択します")
                    }

                    Picker(
                        "ファイル名形式",
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
                    .accessibilityLabel("ファイル名形式")
                    .accessibilityHint("ファイル名の命名規則を選択します")

                    Picker(
                        "ファイル形式",
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
                    .accessibilityLabel("ファイル形式")
                    .accessibilityHint("保存するファイルの拡張子を選択します")

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
                    .help("ファイルに作成日時やアプリ情報を含めます")
                    .accessibilityLabel("メタデータを含める")
                    .accessibilityHint("ファイルに作成日時やアプリ情報を含めます")
                }
            } header: {
                Text("ファイル出力")
            } footer: {
                if store.settings.output.isEnabled {
                    Text("文字起こし結果をテキストファイルとして保存します")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
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
    GeneralSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 500, height: 400)
}
