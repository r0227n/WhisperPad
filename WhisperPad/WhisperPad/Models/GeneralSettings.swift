//
//  GeneralSettings.swift
//  WhisperPad
//

import Foundation

/// 一般設定
///
/// アプリケーションの基本的な動作設定を管理します。
struct GeneralSettings: Codable, Equatable, Sendable {
    /// ログイン時に自動起動するかどうか
    var launchAtLogin: Bool = false

    /// 文字起こし完了時に通知を表示するかどうか
    var showNotificationOnComplete: Bool = true

    /// 文字起こし完了時にサウンドを再生するかどうか
    var playSoundOnComplete: Bool = true

    /// メニューバーアイコンのスタイル
    var menuBarIconStyle: MenuBarIconStyle = .standard

    /// デフォルト設定
    static let `default` = GeneralSettings()
}

// MARK: - MenuBarIconStyle

extension GeneralSettings {
    /// メニューバーアイコンスタイル
    enum MenuBarIconStyle: String, Codable, CaseIterable, Sendable {
        /// 標準スタイル
        case standard

        /// モノクロスタイル
        case monochrome

        /// カラフルスタイル
        case colorful

        /// 表示名
        var displayName: String {
            switch self {
            case .standard:
                "標準"
            case .monochrome:
                "モノクロ"
            case .colorful:
                "カラー"
            }
        }
    }
}
