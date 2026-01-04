//
//  AlertHelper.swift
//  WhisperPad
//

import AppKit
import Foundation

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
@MainActor
func showLocalizedAlert(
    style: NSAlert.Style,
    titleKey: String,
    message: String,
    languageCode: String,
    buttonTitleKey: String = "common.ok"
) {
    NSApp.activate(ignoringOtherApps: true)

    let alert = NSAlert()
    alert.alertStyle = style
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
