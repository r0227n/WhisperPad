//
//  FileOutputSettings.swift
//  WhisperPad
//

import Foundation

/// ファイル出力設定
///
/// 文字起こし結果をファイルに保存する際の設定を管理します。
struct FileOutputSettings: Codable, Equatable, Sendable {
    /// クリップボードにコピーするかどうか
    var copyToClipboard: Bool = true

    /// ファイル出力が有効かどうか
    var isEnabled: Bool = false

    /// 出力先ディレクトリ
    var outputDirectory: URL

    /// ファイル名形式
    var fileNameFormat: FileNameFormat = .dateTime

    /// ファイル拡張子
    var fileExtension: FileExtension = .txt

    /// メタデータを含めるかどうか
    var includeMetadata: Bool = true

    /// デフォルト設定
    static var `default`: FileOutputSettings {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        return FileOutputSettings(
            outputDirectory: documentsDirectory.appendingPathComponent("WhisperPad")
        )
    }
}

// MARK: - FileNameFormat

extension FileOutputSettings {
    /// ファイル名形式
    enum FileNameFormat: String, Codable, CaseIterable, Sendable {
        /// 日時形式 (WhisperPad_yyyyMMdd_HHmmss)
        case dateTime

        /// タイムスタンプ形式 (WhisperPad_1704067200)
        case timestamp

        /// 連番形式 (WhisperPad_001)
        case sequential
    }
}

// MARK: - FileExtension

extension FileOutputSettings {
    /// ファイル拡張子
    enum FileExtension: String, Codable, CaseIterable, Sendable {
        /// テキストファイル
        case txt

        /// マークダウンファイル
        case md
    }
}

// MARK: - File Name Generation

extension FileOutputSettings {
    /// ファイル名を生成
    ///
    /// - Parameter sequentialNumber: 連番形式の場合に使用する番号
    /// - Returns: 拡張子を含むファイル名
    func generateFileName(sequentialNumber: Int = 1) -> String {
        let baseName: String

        switch fileNameFormat {
        case .dateTime:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            baseName = "WhisperPad_\(formatter.string(from: Date()))"

        case .timestamp:
            let timestamp = Int(Date().timeIntervalSince1970)
            baseName = "WhisperPad_\(timestamp)"

        case .sequential:
            baseName = String(format: "WhisperPad_%03d", sequentialNumber)
        }

        return "\(baseName).\(fileExtension.rawValue)"
    }

    /// 完全なファイルパスを生成
    ///
    /// - Parameter sequentialNumber: 連番形式の場合に使用する番号
    /// - Returns: 出力先ディレクトリを含む完全なファイル URL
    func generateFilePath(sequentialNumber: Int = 1) -> URL {
        outputDirectory.appendingPathComponent(generateFileName(sequentialNumber: sequentialNumber))
    }
}
