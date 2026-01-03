//
//  ModelSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// モデル設定タブ
///
/// WhisperKit モデルの選択、ダウンロード、ストレージ管理を行います。
/// 検索・フィルタリング機能付きのリスト型UIを提供します。
struct ModelSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    // MARK: - Local State for Filtering

    @State private var searchText = ""
    @State private var downloadFilter = ModelDownloadFilter.all

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Active Model Section

                activeModelSection

                Divider()

                // MARK: - Search & Filter Section

                searchFilterSection

                // MARK: - Model List Section

                modelListSection

                Divider()

                // MARK: - Storage Section

                storageSection
            }
            .padding()
        }
        .confirmationDialog(
            String(localized: "model.delete.confirm.title", comment: "Delete model?"),
            isPresented: Binding(
                get: { store.modelToDelete != nil },
                set: { if !$0 { store.send(.cancelDeleteModel) } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "common.delete", comment: "Delete"), role: .destructive) {
                store.send(.confirmDeleteModel)
            }
            Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) {
                store.send(.cancelDeleteModel)
            }
        } message: {
            if let modelName = store.modelToDelete {
                Text(
                    String(
                        localized: "model.delete.confirm.message",
                        defaultValue: "「\(modelName)」will be deleted. You will need to download it again to use it.",
                        comment: "Delete confirmation message"
                    )
                )
            }
        }
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }

    // MARK: - Active Model Section

    private var activeModelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "model.active.section", comment: "Active Model"),
                systemImage: "cpu"
            )
            .font(.headline)

            HStack(spacing: 20) {
                // モデル選択
                HStack {
                    Text(String(localized: "model.active.label", comment: "Model"))
                        .foregroundStyle(.secondary)
                    Picker("", selection: validatedModelSelection) {
                        if store.downloadedModels.isEmpty {
                            Text(String(localized: "model.active.empty", comment: "Please download a model"))
                                .tag("")
                        }
                        ForEach(store.downloadedModels, id: \.id) { model in
                            HStack {
                                Text(model.displayName)
                                if model.isRecommended {
                                    Text(String(localized: "model.active.recommended", comment: "Recommended"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(store.downloadedModels.isEmpty)
                    .frame(minWidth: 120)
                }

                // 言語選択
                HStack {
                    Text(String(localized: "model.active.language", comment: "Language"))
                        .foregroundStyle(.secondary)
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.settings.transcription.language },
                            set: { newValue in
                                var transcription = store.settings.transcription
                                transcription.language = newValue
                                store.send(.updateTranscriptionSettings(transcription))
                            }
                        )
                    ) {
                        ForEach(
                            TranscriptionSettings.TranscriptionLanguage.allCases,
                            id: \.self
                        ) { language in
                            Text(language.localizedKey).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                }

                Spacer()
            }

            if store.downloadedModels.isEmpty {
                Text(String(localized: "model.active.download_prompt", comment: "Download a model from the list below"))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Search & Filter Section

    private var searchFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "model.list.section", comment: "Available Models"),
                systemImage: "square.stack.3d.up"
            )
            .font(.headline)

            ModelSearchFilterBar(
                searchText: $searchText,
                downloadFilter: $downloadFilter
            )
        }
    }

    // MARK: - Model List Section

    private var modelListSection: some View {
        Group {
            if store.isLoadingModels {
                loadingView
            } else if filteredModels.isEmpty {
                emptyStateView
            } else {
                modelList
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text(String(localized: "model.list.loading", comment: "Loading models..."))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 40)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(String(localized: "model.list.no_results", comment: "No models match the criteria"))
                .foregroundStyle(.secondary)
            Button(String(localized: "model.filter.reset", comment: "Reset filters")) {
                searchText = ""
                downloadFilter = .all
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 40)
    }

    private var modelList: some View {
        VStack(spacing: 0) {
            ForEach(filteredModels) { model in
                ModelListRow(
                    model: model,
                    isDownloading: store.downloadingModelName == model.id,
                    downloadProgress: store.downloadProgress[model.id] ?? 0,
                    onDownload: { store.send(.downloadModel(model.id)) },
                    onDelete: { store.send(.deleteModelButtonTapped(model.id)) }
                )
                if model.id != filteredModels.last?.id {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "model.storage.section", comment: "Storage"),
                systemImage: "internaldrive"
            )
            .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(localized: "model.storage.usage", comment: "Usage"))
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(
                            fromByteCount: store.storageUsage,
                            countStyle: .file
                        ))
                        .fontWeight(.medium)
                    }

                    HStack {
                        Text(String(localized: "model.storage.location", comment: "Location"))
                            .foregroundStyle(.secondary)
                        if let customURL = store.settings.transcription.customStorageURL {
                            Text(customURL.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text(String(localized: "model.storage.default", comment: "Default"))
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(String(localized: "common.change", comment: "Change...")) {
                        store.send(.selectStorageLocation)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if store.settings.transcription.customStorageURL != nil {
                        Button(String(localized: "common.reset", comment: "Reset")) {
                            store.send(.resetStorageLocation)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Text(String(
                localized: "model.storage.footer",
                comment: "Models are stored on device and can be used offline"
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Computed Properties

    /// 検証済みのモデル選択 Binding
    private var validatedModelSelection: Binding<String> {
        Binding(
            get: {
                guard !store.downloadedModels.isEmpty else {
                    return ""
                }
                let currentModel = store.settings.transcription.modelName
                if store.downloadedModels.contains(where: { $0.id == currentModel }) {
                    return currentModel
                }
                return store.downloadedModels.first?.id ?? ""
            },
            set: { store.send(.selectModel($0)) }
        )
    }

    /// フィルタリング済みのモデル一覧
    private var filteredModels: [WhisperModel] {
        store.availableModels.filter { model in
            // 検索テキストでフィルタリング（部分一致、大文字小文字を無視）
            let searchLower = searchText.lowercased()
            let matchesSearch = searchText.isEmpty ||
                model.displayName.lowercased().contains(searchLower) ||
                model.id.lowercased().contains(searchLower)

            // ダウンロード状態フィルター
            let matchesDownload = downloadFilter.matches(isDownloaded: model.isDownloaded)

            return matchesSearch && matchesDownload
        }
    }
}

// MARK: - Preview

#Preview {
    ModelSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                availableModels: [
                    WhisperModel.from(
                        id: "openai_whisper-tiny",
                        isDownloaded: true,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-tiny.en",
                        isDownloaded: false,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-base",
                        isDownloaded: true,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-small",
                        isDownloaded: true,
                        isRecommended: true
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-small.en",
                        isDownloaded: false,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-medium",
                        isDownloaded: false,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-large-v3",
                        isDownloaded: false,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-large-v3-turbo",
                        isDownloaded: false,
                        isRecommended: false
                    )
                ],
                downloadedModels: [
                    WhisperModel.from(
                        id: "openai_whisper-tiny",
                        isDownloaded: true,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-base",
                        isDownloaded: true,
                        isRecommended: false
                    ),
                    WhisperModel.from(
                        id: "openai_whisper-small",
                        isDownloaded: true,
                        isRecommended: true
                    )
                ],
                storageUsage: 500_000_000
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 700)
}

#Preview("Loading") {
    ModelSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                isLoadingModels: true
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 700)
}

#Preview("Empty") {
    ModelSettingsTab(
        store: Store(
            initialState: SettingsFeature.State(
                availableModels: [],
                downloadedModels: []
            )
        ) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 700)
}
