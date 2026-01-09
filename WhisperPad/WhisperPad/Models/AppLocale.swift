//
//  AppLocale.swift
//  WhisperPad
//

import Foundation
import SwiftUI

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

    /// 解決済み言語コード
    ///
    /// システム設定の場合はシステムの優先言語を使用し、
    /// それ以外の場合は指定された言語コードを返します。
    var resolvedLanguageCode: String {
        if let identifier {
            return identifier
        }
        // .system の場合、システムの優先言語を使用
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        return Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
    }

    /// デフォルト値
    static let `default` = AppLocale.system

    /// SwiftUI の Locale オブジェクトに変換
    var locale: Locale {
        switch self {
        case .system:
            Locale.current // システムのロケールを使用
        case .en:
            Locale(identifier: "en")
        case .ja:
            Locale(identifier: "ja")
        }
    }

    /// 言語固有のローカライズバンドル
    ///
    /// 指定された言語の.lprojバンドルを取得します。
    /// String(localized:bundle:locale:)で使用することで、
    /// アプリ内言語切り替えを実現します。
    var bundle: Bundle {
        switch self {
        case .system:
            return Bundle.main
        case .en, .ja:
            guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
                  let bundle = Bundle(path: path)
            else {
                return Bundle.main
            }
            return bundle
        }
    }

    /// ローカライズキー
    var localizedKey: LocalizedStringKey {
        switch self {
        case .system: "locale.system"
        case .en: "locale.english"
        case .ja: "locale.japanese"
        }
    }

    /// ローカライズ文字列を取得
    ///
    /// 指定されたキーに対応するローカライズ文字列を、
    /// このAppLocaleの言語設定に基づいて取得します。
    ///
    /// - Parameter key: ローカライズキー
    /// - Returns: ローカライズされた文字列
    func localized(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle, locale: locale)
    }
}

// MARK: - Environment Key

private struct AppLocaleKey: EnvironmentKey {
    static let defaultValue: AppLocale = .system
}

extension EnvironmentValues {
    /// アプリのローカライズ設定
    var appLocale: AppLocale {
        get { self[AppLocaleKey.self] }
        set { self[AppLocaleKey.self] = newValue }
    }
}
