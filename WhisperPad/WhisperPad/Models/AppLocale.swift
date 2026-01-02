//
//  AppLocale.swift
//  WhisperPad
//

import Foundation

/// アプリケーションの言語設定
///
/// ユーザーが選択可能な言語オプションを定義します。
enum AppLocale: String, Codable, Equatable, Sendable, CaseIterable {
    /// 自動（システムの言語設定に従う）
    case system

    /// 英語
    case en

    /// 日本語
    case ja

    /// 表示名（ローカライズ済み）
    var displayName: String {
        switch self {
        case .system:
            String(localized: "locale.system", comment: "Auto (System)")
        case .en:
            String(localized: "locale.english", comment: "English")
        case .ja:
            String(localized: "locale.japanese", comment: "Japanese")
        }
    }

    /// ロケール識別子
    ///
    /// - Returns: ロケール識別子。システムの場合は nil
    var identifier: String? {
        switch self {
        case .system:
            nil
        case .en:
            "en"
        case .ja:
            "ja"
        }
    }

    /// デフォルト値
    static let `default` = AppLocale.system
}
