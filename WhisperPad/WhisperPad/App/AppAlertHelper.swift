//
//  AppAlertHelper.swift
//  WhisperPad
//

import AppKit
import Foundation
import os.log

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

// MARK: - Localized Alert Function

/// ローカライズされたアラートダイアログを表示する
///
/// アプリをアクティブ化し、ローカライズされた NSAlert を作成してモーダル表示する。
/// アプリ全体のアラート表示ロジックを一元化するためのヘルパー関数。
///
/// - Parameters:
///   - style: アラートスタイル (.critical, .warning, .informational)
///   - titleKey: アラートタイトルのローカライゼーションキー
///   - message: 表示する情報テキスト（既にローカライズ済みまたはフォーマット済み）
///   - languageCode: ローカライゼーション用の言語コード（例: "en", "ja"）
///   - buttonTitleKey: OK ボタンのローカライゼーションキー（デフォルト: "common.ok"）
///   - iconSettings: メニューバーアイコン設定（style に応じてアイコンを自動選択）
@MainActor
func showLocalizedAlert(
    style: NSAlert.Style,
    titleKey: String,
    message: String,
    languageCode: String,
    buttonTitleKey: String = "common.ok",
    iconSettings: MenuBarIconSettings
) {
    NSApp.activate(ignoringOtherApps: true)

    let alert = NSAlert()
    alert.alertStyle = style

    // style に応じた StatusIconConfig を取得
    let iconConfig: StatusIconConfig = switch style {
    case .critical:
        iconSettings.error
    case .warning:
        iconSettings.paused
    case .informational:
        iconSettings.idle
    @unknown default:
        iconSettings.error
    }

    #if DEBUG
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
        category: "AlertHelper"
    )
    logger.debug(
        "Alert icon config: symbol=\(iconConfig.symbolName), color=\(iconConfig.color.description)"
    )
    #endif

    // SF Symbol から NSImage を作成してアイコンに設定（NSAlert用に適切なサイズを指定）
    if let icon = NSImage(systemSymbolName: iconConfig.symbolName, accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: 48, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: iconConfig.color))
        alert.icon = icon.withSymbolConfiguration(config)
    }

    alert.messageText = Bundle.main.localizedString(
        forKey: titleKey,
        preferredLanguage: languageCode
    )
    alert.informativeText = message
    alert.addButton(
        withTitle: Bundle.main.localizedString(
            forKey: buttonTitleKey,
            preferredLanguage: languageCode
        )
    )

    alert.runModal()
}

// MARK: - Bundle Extension

extension Bundle {
    /// 指定した言語でローカライズされた文字列を取得
    func localizedString(forKey key: String, preferredLanguage: String) -> String {
        // 指定言語の.lprojバンドルを探す
        if let path = self.path(forResource: preferredLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        // フォールバック: メインバンドルのローカライズ
        return self.localizedString(forKey: key, value: nil, table: nil)
    }
}
