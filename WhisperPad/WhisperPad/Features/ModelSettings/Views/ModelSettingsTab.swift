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
    @Bindable var store: StoreOf<ModelSettingsFeature>
    @Environment(\.appLocale) private var appLocale

    // MARK: - Local State for Filtering

    @State private var searchText = ""
    @State private var downloadFilter = ModelDownloadFilter.all

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Active Model Section

                ActiveModelSection(
                    downloadedModels: store.downloadedModels,
                    selectedModel: validatedModelSelection,
                    selectedLanguage: Binding(
                        get: { store.transcription.language },
                        set: { newValue in
                            var transcription = store.transcription
                            transcription.language = newValue
                            store.send(.updateTranscriptionSettings(transcription))
                        }
                    ),
                    availableLanguages: store.availableLanguages,
                    preferredLocale: store.preferredLocale.locale,
                    appLocale: appLocale
                )

                Divider()

                // MARK: - Search & Filter Section

                searchFilterSection

                // MARK: - Model List Section

                modelListSection

                Divider()

                // MARK: - Storage Section

                StorageSection(
                    storageUsage: store.storageUsage,
                    storageURL: store.modelStorageURL,
                    onChangeLocation: { store.send(.selectStorageLocation) },
                    appLocale: appLocale
                )
            }
            .padding()
        }
        .confirmationDialog(
            appLocale.localized("model.delete.confirm.title"),
            isPresented: Binding(
                get: { store.modelToDelete != nil },
                set: { if !$0 { store.send(.cancelDeleteModel) } }
            ),
            titleVisibility: .visible
        ) {
            Button(appLocale.localized("common.delete"), role: .destructive) {
                store.send(.confirmDeleteModel)
            }
            Button(appLocale.localized("common.cancel"), role: .cancel) {
                store.send(.cancelDeleteModel)
            }
        } message: {
            if let modelName = store.modelToDelete {
                let format = appLocale.localized("model.delete.confirm.message")
                Text(String(format: format, modelName))
            }
        }
        .environment(\.locale, store.preferredLocale.locale)
    }

    // MARK: - Search & Filter Section

    private var searchFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(appLocale.localized("model.list.section"), systemImage: "square.stack.3d.up")
                .font(.headline)

            ModelSearchFilterBar(
                searchText: $searchText,
                downloadFilter: $downloadFilter,
                appLocale: appLocale
            )
        }
    }

    // MARK: - Model List Section

    private var modelListSection: some View {
        Group {
            if store.isLoadingModels {
                ModelLoadingView(appLocale: appLocale)
            } else if filteredModels.isEmpty {
                ModelEmptyStateView(
                    onResetFilters: {
                        searchText = ""
                        downloadFilter = .all
                    },
                    appLocale: appLocale
                )
            } else {
                modelList
            }
        }
    }

    private var modelList: some View {
        VStack(spacing: 0) {
            ForEach(filteredModels) { model in
                ModelListRow(
                    model: model,
                    isDownloading: store.downloadingModelName == model.id,
                    downloadProgress: store.downloadProgress[model.id] ?? 0,
                    onDownload: { store.send(.downloadModel(model.id)) },
                    onDelete: { store.send(.deleteModelButtonTapped(model.id)) },
                    appLocale: appLocale
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

    // MARK: - Computed Properties

    /// 検証済みのモデル選択 Binding
    private var validatedModelSelection: Binding<String> {
        Binding(
            get: {
                guard !store.downloadedModels.isEmpty else {
                    return ""
                }
                let currentModel = store.transcription.modelName
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
            initialState: ModelSettingsFeature.State(
                availableModels: [
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
            ModelSettingsFeature()
        }
    )
    .frame(width: 520, height: 700)
}

#Preview("Loading") {
    ModelSettingsTab(
        store: Store(
            initialState: ModelSettingsFeature.State(
                isLoadingModels: true
            )
        ) {
            ModelSettingsFeature()
        }
    )
    .frame(width: 520, height: 700)
}
