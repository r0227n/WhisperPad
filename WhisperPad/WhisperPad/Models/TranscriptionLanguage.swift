//
//  TranscriptionLanguage.swift
//  WhisperPad
//

import Foundation
import WhisperKit

/// 文字起こしに使用する言語
struct TranscriptionLanguage: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// 言語コード（ISO 639-1形式、例: "en", "ja", "zh"）
    let code: String

    /// 英語名（WhisperKitの言語辞書から取得）
    let englishName: String

    /// ID（Identifiable準拠のため）
    var id: String { code }

    /// 自動検出を表す特別な言語
    static let auto = TranscriptionLanguage(code: "auto", englishName: "auto")

    /// WhisperKitからサポートされているすべての言語を取得
    static var allSupported: [TranscriptionLanguage] {
        // WhisperKitの言語辞書から言語を取得
        let languagesDict = Constants.languages

        // コードごとにグループ化し、最も短い名前を選択（正規名を優先）
        var uniqueLanguages: [String: String] = [:]
        for (name, code) in languagesDict {
            if let existingName = uniqueLanguages[code] {
                // より短い名前を優先（例: "chinese" より "zh" を選択）
                if name.count < existingName.count {
                    uniqueLanguages[code] = name
                }
            } else {
                uniqueLanguages[code] = name
            }
        }

        // TranscriptionLanguageモデルに変換
        var languages = uniqueLanguages.map {
            TranscriptionLanguage(code: $0.key, englishName: $0.value)
        }

        // 表示名でソート
        languages.sort { lhs, rhs in
            lhs.displayName.localizedCompare(rhs.displayName) == .orderedAscending
        }

        // 自動検出を先頭に追加
        return [.auto] + languages
    }

    /// UI表示用のローカライズされた名前
    var displayName: String {
        displayName(locale: .current)
    }

    /// UI表示用のローカライズされた名前（指定されたロケールを使用）
    /// - Parameter locale: 使用するロケール
    /// - Returns: ローカライズされた言語名
    func displayName(locale: Locale) -> String {
        let key = localizedKey
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        // 指定されたロケールに対応する言語バンドルから翻訳を取得
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            // ローカライゼーションが見つからない場合、英語名の先頭を大文字にして使用
            if localized != key {
                return localized
            }
        }

        // フォールバック: メインバンドルから取得を試みる
        let mainLocalized = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        if mainLocalized != key {
            return mainLocalized
        }

        // 最終フォールバック: 英語名を使用
        return englishName.prefix(1).uppercased() + englishName.dropFirst()
    }

    /// ローカライゼーションキー
    var localizedKey: String {
        if code == "auto" {
            return "transcription.language.auto"
        }
        return "transcription.language.\(code)"
    }

    /// WhisperKitに渡す言語コード（自動検出の場合はnil）
    var whisperCode: String? {
        code == "auto" ? nil : code
    }
}

// MARK: - Codable

extension TranscriptionLanguage {
    enum CodingKeys: String, CodingKey {
        case code
        case englishName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 新しい形式（構造体）としてデコードを試みる
        if let code = try? container.decode(String.self, forKey: .code),
           let englishName = try? container.decode(String.self, forKey: .englishName) {
            self.code = code
            self.englishName = englishName
        }
        // 古い形式（列挙型の文字列値）からの移行
        else if let singleValue = try? decoder.singleValueContainer(),
                let code = try? singleValue.decode(String.self) {
            self.code = code
            // 既知の言語コードから英語名を検索
            if code == "auto" {
                self.englishName = "auto"
            } else if let name = Constants.languages.first(where: { $0.value == code })?.key {
                self.englishName = name
            } else {
                // 見つからない場合はコードをそのまま使用
                self.englishName = code
            }
        }
        // デコードに失敗した場合は自動検出にフォールバック
        else {
            self = .auto
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(englishName, forKey: .englishName)
    }
}
