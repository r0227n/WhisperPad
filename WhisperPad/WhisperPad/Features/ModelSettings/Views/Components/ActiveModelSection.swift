//
//  ActiveModelSection.swift
//  WhisperPad
//

import SwiftUI

/// Active Model Section
///
/// Displays the currently active model selection and language picker.
struct ActiveModelSection: View {
    /// ダウンロード済みモデル一覧
    let downloadedModels: [WhisperModel]
    /// 選択中のモデル
    @Binding var selectedModel: String
    /// 選択中の言語
    @Binding var selectedLanguage: TranscriptionLanguage
    /// 利用可能な言語一覧
    let availableLanguages: [TranscriptionLanguage]
    /// 優先ロケール
    let preferredLocale: Locale
    /// ローカライズ設定
    let appLocale: AppLocale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(appLocale.localized("model.active.section"), systemImage: "cpu")
                .font(.headline)

            HStack(spacing: 20) {
                // Model selection
                HStack {
                    Text(appLocale.localized("model.active.label"))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedModel) {
                        if downloadedModels.isEmpty {
                            Text(appLocale.localized("model.active.empty"))
                                .tag("")
                        }
                        ForEach(downloadedModels, id: \.id) { model in
                            HStack {
                                Text(model.displayName)
                                if model.isRecommended {
                                    Text(appLocale.localized("model.active.recommended"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(downloadedModels.isEmpty)
                    .frame(minWidth: 120)
                }

                // Language selection
                HStack {
                    Text(appLocale.localized("model.active.language"))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedLanguage) {
                        ForEach(availableLanguages) { language in
                            Text(language.displayName(locale: preferredLocale))
                                .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                }

                Spacer()
            }

            if downloadedModels.isEmpty {
                Text(appLocale.localized("model.active.download_prompt"))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedModel = "openai_whisper-small"
    @Previewable @State var selectedLanguage = TranscriptionLanguage.auto

    ActiveModelSection(
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
        selectedModel: $selectedModel,
        selectedLanguage: $selectedLanguage,
        availableLanguages: TranscriptionLanguage.allSupported,
        preferredLocale: .current,
        appLocale: .system
    )
    .padding()
}

#Preview("Empty") {
    @Previewable @State var selectedModel = ""
    @Previewable @State var selectedLanguage = TranscriptionLanguage.auto

    ActiveModelSection(
        downloadedModels: [],
        selectedModel: $selectedModel,
        selectedLanguage: $selectedLanguage,
        availableLanguages: TranscriptionLanguage.allSupported,
        preferredLocale: .current,
        appLocale: .system
    )
    .padding()
}
