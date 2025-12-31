//
//  ModelSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// モデル設定タブ
///
/// WhisperKit モデルの選択、ダウンロード、ストレージ管理を行います。
struct ModelSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // MARK: - モデル選択

            Section {
                Picker(
                    "使用モデル",
                    selection: Binding(
                        get: { store.settings.transcription.modelName },
                        set: { store.send(.selectModel($0)) }
                    )
                ) {
                    ForEach(downloadedModels, id: \.id) { model in
                        HStack {
                            Text(model.displayName)
                            if model.isRecommended {
                                Text("推奨")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(model.id)
                    }
                }
                .disabled(downloadedModels.isEmpty)
            } header: {
                Text("モデル選択")
            } footer: {
                if downloadedModels.isEmpty {
                    Text("モデルをダウンロードしてください")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 言語設定

            Section {
                Picker(
                    "認識言語",
                    selection: Binding(
                        get: { store.settings.transcription.language },
                        set: { newValue in
                            var transcription = store.settings.transcription
                            transcription.language = newValue
                            store.send(.updateTranscriptionSettings(transcription))
                        }
                    )
                ) {
                    ForEach(TranscriptionSettings.TranscriptionLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            } header: {
                Text("言語")
            } footer: {
                Text("「自動検出」を選択すると、音声から言語を自動的に判別します")
                    .foregroundStyle(.secondary)
            }

            // MARK: - 利用可能なモデル

            Section {
                if store.isLoadingModels {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("モデル一覧を取得中...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(store.availableModels) { model in
                        ModelDownloadRow(
                            model: model,
                            isDownloading: store.downloadingModelName == model.id,
                            downloadProgress: store.downloadProgress[model.id] ?? 0,
                            onDownload: { store.send(.downloadModel(model.id)) },
                            onDelete: { store.send(.deleteModel(model.id)) }
                        )
                    }
                }

                Button {
                    store.send(.fetchModels)
                } label: {
                    Label("モデル一覧を更新", systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoadingModels)
            } header: {
                Text("利用可能なモデル")
            }

            // MARK: - ストレージ

            Section {
                HStack {
                    Text("使用量")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: store.storageUsage, countStyle: .file))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("保存先")
                    Spacer()
                    if let customURL = store.settings.transcription.customStorageURL {
                        Text(customURL.path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("デフォルト")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Button("保存先を変更...") {
                        store.send(.selectStorageLocation)
                    }

                    if store.settings.transcription.customStorageURL != nil {
                        Button("デフォルトに戻す") {
                            store.send(.resetStorageLocation)
                        }
                    }
                }
            } header: {
                Text("ストレージ")
            } footer: {
                Text("モデルはデバイス上に保存され、オフラインで使用できます")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    /// ダウンロード済みモデルのフィルタリング
    private var downloadedModels: [WhisperModel] {
        store.availableModels.filter(\.isDownloaded)
    }
}

// MARK: - Preview

#Preview {
    ModelSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                availableModels: [
                    WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false),
                    WhisperModel.from(id: "openai_whisper-base", isDownloaded: true, isRecommended: false),
                    WhisperModel.from(id: "openai_whisper-small", isDownloaded: true, isRecommended: true),
                    WhisperModel.from(id: "openai_whisper-medium", isDownloaded: false, isRecommended: false),
                    WhisperModel.from(id: "openai_whisper-large-v3", isDownloaded: false, isRecommended: false)
                ],
                storageUsage: 500_000_000
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 500, height: 600)
}
