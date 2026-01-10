//
//  AppReducerHelpers.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation

// MARK: - Helper Methods

extension AppReducer {
    func handleCancelRecording(state: inout State) -> Effect<Action> {
        let showConfirmation = state.settings.settings.general.showCancelConfirmation

        if showConfirmation {
            let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)
            var currentGeneral = state.settings.settings.general

            return .run { send in
                let (shouldCancel, dontShowAgain) = await AppAlertHelper.showCancelConfirmationDialog(
                    languageCode: languageCode
                )

                if dontShowAgain {
                    currentGeneral.showCancelConfirmation = false
                    await send(.settings(.updateGeneralSettings(currentGeneral)))
                }

                if shouldCancel {
                    await send(.confirmCancelRecording)
                }
            }
        } else {
            return .send(.confirmCancelRecording)
        }
    }

    func handlePartialSuccess(
        url: URL,
        usedSegments: Int,
        totalSegments: Int,
        state: State
    ) -> Effect<Action> {
        let language = state.settings.settings.transcription.language.whisperCode
        let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)

        return .run { send in
            await AppAlertHelper.showPartialSuccessDialog(
                usedSegments: usedSegments,
                totalSegments: totalSegments,
                languageCode: languageCode
            )
            await send(.transcription(.startTranscription(audioURL: url, language: language)))
        }
    }

    func handleWhisperKitInitializing(state: State) -> Effect<Action> {
        let languageCode = getLanguageCode(from: state.settings.settings.general.preferredLocale)

        return .run { _ in
            await AppAlertHelper.showWhisperKitInitializingDialog(languageCode: languageCode)
        }
    }

    func handleTranscriptionCompleted(text: String, state: State) -> Effect<Action> {
        let outputSettings = state.settings.settings.output
        let generalSettings = state.settings.settings.general

        return .run { [outputClient, userDefaultsClient, summarizationClient, clock] send in
            // 出力テキストを準備（要約が有効な場合は要約を適用）
            var outputText = text

            if generalSettings.appleSummarizationEnabled, summarizationClient.isAvailable() {
                do {
                    outputText = try await summarizationClient.summarize(text)
                } catch {
                    // 要約に失敗した場合は元のテキストを使用
                    outputText = text
                }
            }

            if outputSettings.copyToClipboard {
                _ = await outputClient.copyToClipboard(outputText)
            }

            await handleOutputAndNotification(
                text: outputText,
                outputSettings: outputSettings,
                generalSettings: generalSettings,
                outputClient: outputClient,
                userDefaultsClient: userDefaultsClient
            )

            if generalSettings.playSoundOnComplete {
                await outputClient.playCompletionSound()
            }

            try await clock.sleep(for: .seconds(3))
            await send(.resetToIdle)
        }
        .cancellable(id: "autoReset")
    }

    func handleOutputAndNotification(
        text: String,
        outputSettings: FileOutputSettings,
        generalSettings: GeneralSettings,
        outputClient: OutputClient,
        userDefaultsClient: UserDefaultsClient
    ) async {
        let notificationTitle = generalSettings.notificationTitle.isEmpty
            ? String(localized: "notification.default.title")
            : generalSettings.notificationTitle
        let transcriptionCompleteMessage = generalSettings.transcriptionCompleteMessage.isEmpty
            ? String(localized: "notification.transcription.complete.message")
            : generalSettings.transcriptionCompleteMessage

        if outputSettings.isEnabled {
            var resolvedOutputSettings = outputSettings

            if let bookmarkData = outputSettings.outputBookmarkData,
               let resolvedURL = await userDefaultsClient.resolveBookmark(bookmarkData) {
                resolvedOutputSettings.outputDirectory = resolvedURL
            }

            do {
                let url = try await outputClient.saveToFile(text, resolvedOutputSettings)
                if generalSettings.showNotificationOnComplete {
                    await outputClient.showNotification(
                        notificationTitle,
                        String(
                            format: String(localized: "notification.file.save.success"),
                            url.lastPathComponent
                        )
                    )
                }
            } catch {
                if generalSettings.showNotificationOnComplete {
                    await outputClient.showNotification(
                        notificationTitle,
                        String(
                            format: String(localized: "notification.file.save.failure"),
                            error.localizedDescription
                        )
                    )
                }
            }
        } else {
            if generalSettings.showNotificationOnComplete {
                await outputClient.showNotification(
                    notificationTitle,
                    transcriptionCompleteMessage
                )
            }
        }
    }

    func getLanguageCode(from preferredLocale: AppLocale) -> String {
        preferredLocale.resolvedLanguageCode
    }
}
