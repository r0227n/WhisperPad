//
//  AppAlertHelper.swift
//  WhisperPad
//

import AppKit
import Foundation

// MARK: - Alert Helpers

enum AppAlertHelper {
    @MainActor
    static func showCancelConfirmationDialog(languageCode: String) -> (shouldCancel: Bool, dontShowAgain: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = Bundle.main.localizedString(
            forKey: "recording.cancel_confirmation.alert.title",
            preferredLanguage: languageCode
        )
        alert.informativeText = Bundle.main.localizedString(
            forKey: "recording.cancel_confirmation.alert.message",
            preferredLanguage: languageCode
        )

        let checkboxText = Bundle.main.localizedString(
            forKey: "recording.cancel_confirmation.alert.dont_show_again",
            preferredLanguage: languageCode
        )
        let checkbox = NSButton(checkboxWithTitle: checkboxText, target: nil, action: nil)
        checkbox.state = .off
        alert.accessoryView = checkbox

        alert.addButton(
            withTitle: Bundle.main.localizedString(
                forKey: "recording.cancel_confirmation.alert.continue",
                preferredLanguage: languageCode
            )
        )
        alert.addButton(
            withTitle: Bundle.main.localizedString(
                forKey: "recording.cancel_confirmation.alert.discard",
                preferredLanguage: languageCode
            )
        )

        let response = alert.runModal()
        let shouldCancel = response == .alertSecondButtonReturn
        let dontShowAgain = checkbox.state == .on

        return (shouldCancel, dontShowAgain)
    }

    @MainActor
    static func showPartialSuccessDialog(usedSegments: Int, totalSegments: Int, languageCode: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = Bundle.main.localizedString(
            forKey: "recording.partial_success.alert.title",
            preferredLanguage: languageCode
        )
        let messageFormat = Bundle.main.localizedString(
            forKey: "recording.partial_success.alert.message",
            preferredLanguage: languageCode
        )
        alert.informativeText = String(format: messageFormat, usedSegments, totalSegments)
        alert.addButton(
            withTitle: Bundle.main.localizedString(
                forKey: "common.ok",
                preferredLanguage: languageCode
            )
        )
        alert.runModal()
    }

    @MainActor
    static func showWhisperKitInitializingDialog(languageCode: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = Bundle.main.localizedString(
            forKey: "recording.whisperkit_initializing.alert.title",
            preferredLanguage: languageCode
        )
        alert.informativeText = Bundle.main.localizedString(
            forKey: "recording.whisperkit_initializing.alert.message",
            preferredLanguage: languageCode
        )
        alert.addButton(
            withTitle: Bundle.main.localizedString(
                forKey: "common.ok",
                preferredLanguage: languageCode
            )
        )
        alert.runModal()
    }
}
