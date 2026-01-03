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
            Text("model.delete.confirm.title"),
            isPresented: Binding(
                get: { store.modelToDelete != nil },
                set: { if !$0 { store.send(.cancelDeleteModel) } }
            ),
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                store.send(.confirmDeleteModel)
            } label: {
                Text("common.delete")
            }
            Button(role: .cancel) {
                store.send(.cancelDeleteModel)
            } label: {
                Text("common.cancel")
            }
        } message: {
            if let modelName = store.modelToDelete {
                Text("model.delete.confirm.message \(modelName)")
            }
        }
        .environment(\.locale, store.settings.general.preferredLocale.locale)
    }

    // MARK: - Active Model Section

    private var activeModelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("model.active.section", systemImage: "cpu")
                .font(.headline)

            HStack(spacing: 20) {
                // モデル選択
                HStack {
                    Text("model.active.label")
                        .foregroundStyle(.secondary)
                    Picker("", selection: validatedModelSelection) {
                        if store.downloadedModels.isEmpty {
                            Text("model.active.empty")
                                .tag("")
                        }
                        ForEach(store.downloadedModels, id: \.id) { model in
                            HStack {
                                Text(model.displayName)
                                if model.isRecommended {
                                    Text("model.active.recommended")
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
                    Text("model.active.language")
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
                        ForEach(store.availableLanguages) { language in
                            Text(language.displayName(locale: store.settings.general.preferredLocale.locale))
                                .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                }

                Spacer()
            }

            if store.downloadedModels.isEmpty {
                Text("model.active.download_prompt")
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
            Label("model.list.section", systemImage: "square.stack.3d.up")
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
            Text("model.list.loading")
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
            Text("model.list.no_results")
                .foregroundStyle(.secondary)
            Button("model.filter.reset") {
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
            Label("model.storage.section", systemImage: "internaldrive")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("model.storage.usage")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(
                            fromByteCount: store.storageUsage,
                            countStyle: .file
                        ))
                        .fontWeight(.medium)
                    }

                    HStack {
                        Text("model.storage.location")
                            .foregroundStyle(.secondary)
                        if let storageURL = store.modelStorageURL {
                            Text(storageURL.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            // フォールバック: パス取得前
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
                }

                Spacer()

                Button("common.change") {
                    store.send(.selectStorageLocation)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
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
