//
//  ActiveModelSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Active Model Section
///
/// Displays the currently active model selection and language picker.
struct ActiveModelSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("model.active.section", systemImage: "cpu")
                .font(.headline)

            HStack(spacing: 20) {
                // Model selection
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

                // Language selection
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
}

// MARK: - Preview

#Preview {
    ActiveModelSection(
        store: Store(
            initialState: SettingsFeature.State(
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
                ]
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
}

#Preview("Empty") {
    ActiveModelSection(
        store: Store(
            initialState: SettingsFeature.State(
                downloadedModels: []
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
}
