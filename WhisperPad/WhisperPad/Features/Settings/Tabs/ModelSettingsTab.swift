//
//  ModelSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Model settings tab
///
/// Manages WhisperKit model selection, download, and storage.
/// Provides list-type UI with search and filtering functionality.
struct ModelSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

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
            L10n.get(.modelDeleteConfirmTitle),
            isPresented: Binding(
                get: { store.modelToDelete != nil },
                set: { if !$0 { store.send(.cancelDeleteModel) } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.get(.modelDelete), role: .destructive) {
                store.send(.confirmDeleteModel)
            }
            Button(L10n.get(.modelCancel), role: .cancel) {
                store.send(.cancelDeleteModel)
            }
        } message: {
            if let modelName = store.modelToDelete {
                Text("\"\(modelName)\" \(L10n.get(.modelDeleteConfirmMessage))")
            }
        }
    }

    // MARK: - Active Model Section

    private var activeModelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.get(.modelActiveModel), systemImage: "cpu")
                .font(.headline)

            HStack(spacing: 20) {
                // Model selection
                HStack {
                    Text(L10n.get(.modelModel))
                        .foregroundStyle(.secondary)
                    Picker("", selection: validatedModelSelection) {
                        if store.downloadedModels.isEmpty {
                            Text(L10n.get(.modelDownloadPrompt))
                                .tag("")
                        }
                        ForEach(store.downloadedModels, id: \.id) { model in
                            HStack {
                                Text(model.displayName)
                                if model.isRecommended {
                                    Text(L10n.get(.modelRecommended))
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

                // Language selection
                HStack {
                    Text(L10n.get(.modelLanguage))
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
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                }

                Spacer()
            }

            if store.downloadedModels.isEmpty {
                Text(L10n.get(.modelDownloadPrompt))
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
            Label(L10n.get(.modelAvailableModels), systemImage: "square.stack.3d.up")
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
            Text(L10n.get(.modelLoading))
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
            Text(L10n.get(.modelNoMatches))
                .foregroundStyle(.secondary)
            Button(L10n.get(.modelResetFilter)) {
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
            Label(L10n.get(.modelStorage), systemImage: "internaldrive")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L10n.get(.modelUsage))
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(
                            fromByteCount: store.storageUsage,
                            countStyle: .file
                        ))
                        .fontWeight(.medium)
                    }

                    HStack {
                        Text(L10n.get(.modelSaveLocation))
                            .foregroundStyle(.secondary)
                        if let customURL = store.settings.transcription.customStorageURL {
                            Text(customURL.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text(L10n.get(.modelDefault))
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(L10n.get(.modelChange)) {
                        store.send(.selectStorageLocation)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if store.settings.transcription.customStorageURL != nil {
                        Button(L10n.get(.modelReset)) {
                            store.send(.resetStorageLocation)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Text(L10n.get(.modelStorageDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Computed Properties

    /// Validated model selection Binding
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

    /// Filtered model list
    private var filteredModels: [WhisperModel] {
        store.availableModels.filter { model in
            // Filter by search text (partial match, case insensitive)
            let searchLower = searchText.lowercased()
            let matchesSearch = searchText.isEmpty ||
                model.displayName.lowercased().contains(searchLower) ||
                model.id.lowercased().contains(searchLower)

            // Download status filter
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
