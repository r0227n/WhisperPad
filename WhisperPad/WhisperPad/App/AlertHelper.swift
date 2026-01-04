//
//  AlertHelper.swift
//  WhisperPad
//

import AppKit
import Foundation
import os.log

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

private extension Bundle {
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
