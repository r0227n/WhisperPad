//
//  GeneralSettings.swift
//  WhisperPad
//

import Foundation

/// 一般設定
///
/// アプリケーションの基本的な動作設定を管理します。
struct GeneralSettings: Equatable, Sendable {
    /// アプリケーションの表示言語
    var preferredLocale: AppLocale = .system

    /// ログイン時に自動起動するかどうか
    var launchAtLogin: Bool = false

    /// 文字起こし完了時に通知を表示するかどうか
    var showNotificationOnComplete: Bool = true

    /// 文字起こし完了時にサウンドを再生するかどうか
    var playSoundOnComplete: Bool = true

    /// メニューバーアイコンのカスタム設定
    var menuBarIconSettings: MenuBarIconSettings = .default

    /// 通知のタイトル
    var notificationTitle: String = ""

    /// 通常録音完了時のメッセージ
    var transcriptionCompleteMessage: String = ""

    /// WhisperKitのアイドルタイムアウトを有効にするかどうか
    var whisperKitIdleTimeoutEnabled: Bool = true

    /// WhisperKitのアイドルタイムアウト時間（分）
    /// 範囲: 5-60分、デフォルト: 15分
    var whisperKitIdleTimeoutMinutes: Int = 15

    /// 録音キャンセル時に確認ダイアログを表示するかどうか
    var showCancelConfirmation: Bool = true

    /// デフォルト設定
    static let `default` = GeneralSettings()
}

// MARK: - Codable

extension GeneralSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case preferredLocale
        case launchAtLogin
        case showNotificationOnComplete
        case playSoundOnComplete
        case menuBarIconSettings
        case notificationTitle
        case transcriptionCompleteMessage
        case whisperKitIdleTimeoutEnabled
        case whisperKitIdleTimeoutMinutes
        case showCancelConfirmation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredLocale = try container.decodeIfPresent(AppLocale.self, forKey: .preferredLocale) ?? .system
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showNotificationOnComplete = try container.decodeIfPresent(
            Bool.self, forKey: .showNotificationOnComplete
        ) ?? true
        playSoundOnComplete = try container.decodeIfPresent(Bool.self, forKey: .playSoundOnComplete) ?? true
        menuBarIconSettings = try container.decodeIfPresent(
            MenuBarIconSettings.self, forKey: .menuBarIconSettings
        ) ?? .default
        notificationTitle = try container.decodeIfPresent(String.self, forKey: .notificationTitle) ?? ""
        transcriptionCompleteMessage = try container.decodeIfPresent(
            String.self, forKey: .transcriptionCompleteMessage
        ) ?? ""
        whisperKitIdleTimeoutEnabled = try container.decodeIfPresent(
            Bool.self, forKey: .whisperKitIdleTimeoutEnabled
        ) ?? true
        whisperKitIdleTimeoutMinutes = try container.decodeIfPresent(
            Int.self, forKey: .whisperKitIdleTimeoutMinutes
        ) ?? 15
        showCancelConfirmation = try container.decodeIfPresent(
            Bool.self, forKey: .showCancelConfirmation
        ) ?? true
    }
}
