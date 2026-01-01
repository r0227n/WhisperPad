//
//  GeneralSettings.swift
//  WhisperPad
//

import Foundation

/// 一般設定
///
/// アプリケーションの基本的な動作設定を管理します。
struct GeneralSettings: Equatable, Sendable {
    /// ログイン時に自動起動するかどうか
    var launchAtLogin: Bool = false

    /// 文字起こし完了時に通知を表示するかどうか
    var showNotificationOnComplete: Bool = true

    /// 文字起こし完了時にサウンドを再生するかどうか
    var playSoundOnComplete: Bool = true

    /// メニューバーアイコンのカスタム設定
    var menuBarIconSettings: MenuBarIconSettings = .default

    /// 通知のタイトル
    var notificationTitle: String = "WhisperPad"

    /// 通常録音完了時のメッセージ
    var transcriptionCompleteMessage: String = "文字起こしが完了しました"

    /// リアルタイム文字起こし完了時のメッセージ
    var streamingCompleteMessage: String = "リアルタイム文字起こしが完了しました"

    /// デフォルト設定
    static let `default` = GeneralSettings()
}

// MARK: - Codable

extension GeneralSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case showNotificationOnComplete
        case playSoundOnComplete
        case menuBarIconSettings
        case notificationTitle
        case transcriptionCompleteMessage
        case streamingCompleteMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showNotificationOnComplete = try container.decodeIfPresent(
            Bool.self, forKey: .showNotificationOnComplete
        ) ?? true
        playSoundOnComplete = try container.decodeIfPresent(Bool.self, forKey: .playSoundOnComplete) ?? true
        menuBarIconSettings = try container.decodeIfPresent(
            MenuBarIconSettings.self, forKey: .menuBarIconSettings
        ) ?? .default
        notificationTitle = try container.decodeIfPresent(String.self, forKey: .notificationTitle) ?? "WhisperPad"
        transcriptionCompleteMessage = try container.decodeIfPresent(
            String.self, forKey: .transcriptionCompleteMessage
        ) ?? "文字起こしが完了しました"
        streamingCompleteMessage = try container.decodeIfPresent(
            String.self, forKey: .streamingCompleteMessage
        ) ?? "リアルタイム文字起こしが完了しました"
    }
}
