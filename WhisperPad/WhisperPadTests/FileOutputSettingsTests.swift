//
//  FileOutputSettingsTests.swift
//  WhisperPadTests
//

import XCTest

@testable import WhisperPad

/// FileOutputSettings のテスト
///
/// ファイル出力設定モデルの各機能をテストします。
final class FileOutputSettingsTests: XCTestCase {
    // MARK: - Default Settings Tests

    /// デフォルト設定が正しいことを確認
    func testDefaultSettings() {
        let settings = FileOutputSettings.default

        XCTAssertFalse(settings.isEnabled)
        XCTAssertTrue(settings.outputDirectory.path.contains("Documents"))
        XCTAssertTrue(settings.outputDirectory.path.contains("WhisperPad"))
        XCTAssertEqual(settings.fileNameFormat, .dateTime)
        XCTAssertEqual(settings.fileExtension, .txt)
        XCTAssertTrue(settings.includeMetadata)
    }

    // MARK: - File Name Generation Tests

    /// 日時形式のファイル名が正しく生成されることを確認
    func testFileNameGeneration_dateTime() {
        var settings = FileOutputSettings.default
        settings.fileNameFormat = .dateTime
        settings.fileExtension = .txt

        let fileName = settings.generateFileName()

        // WhisperPad_YYYYMMDD_HHMMSS.txt 形式
        XCTAssertTrue(fileName.hasPrefix("WhisperPad_"))
        XCTAssertTrue(fileName.hasSuffix(".txt"))
        XCTAssertTrue(fileName.contains("_"))

        // ファイル名の長さを確認 (WhisperPad_YYYYMMDD_HHMMSS.txt = 30文字)
        XCTAssertEqual(fileName.count, 30)
    }

    /// タイムスタンプ形式のファイル名が正しく生成されることを確認
    func testFileNameGeneration_timestamp() {
        var settings = FileOutputSettings.default
        settings.fileNameFormat = .timestamp
        settings.fileExtension = .txt

        let fileName = settings.generateFileName()

        // WhisperPad_TIMESTAMP.txt 形式
        XCTAssertTrue(fileName.hasPrefix("WhisperPad_"))
        XCTAssertTrue(fileName.hasSuffix(".txt"))

        // タイムスタンプ部分が数字であることを確認
        let components = fileName.replacingOccurrences(of: "WhisperPad_", with: "")
            .replacingOccurrences(of: ".txt", with: "")
        XCTAssertNotNil(Int(components))
    }

    /// 連番形式のファイル名が正しく生成されることを確認
    func testFileNameGeneration_sequential() {
        var settings = FileOutputSettings.default
        settings.fileNameFormat = .sequential
        settings.fileExtension = .txt

        let fileName1 = settings.generateFileName(sequentialNumber: 1)
        let fileName5 = settings.generateFileName(sequentialNumber: 5)
        let fileName100 = settings.generateFileName(sequentialNumber: 100)

        XCTAssertEqual(fileName1, "WhisperPad_001.txt")
        XCTAssertEqual(fileName5, "WhisperPad_005.txt")
        XCTAssertEqual(fileName100, "WhisperPad_100.txt")
    }

    /// マークダウン拡張子が正しく適用されることを確認
    func testFileNameGeneration_markdownExtension() {
        var settings = FileOutputSettings.default
        settings.fileNameFormat = .timestamp
        settings.fileExtension = .md

        let fileName = settings.generateFileName()

        XCTAssertTrue(fileName.hasSuffix(".md"))
    }

    /// ファイルパス生成が正しいことを確認
    func testGenerateFilePath() {
        var settings = FileOutputSettings.default
        settings.fileNameFormat = .sequential

        let path = settings.generateFilePath(sequentialNumber: 42)

        XCTAssertTrue(path.path.contains("Documents"))
        XCTAssertTrue(path.path.contains("WhisperPad"))
        XCTAssertTrue(path.lastPathComponent.contains("WhisperPad_042"))
    }

    // MARK: - Codable Tests

    /// エンコード・デコードが正しく動作することを確認
    func testCodable_encodeAndDecode() throws {
        var original = FileOutputSettings.default
        original.isEnabled = true
        original.fileNameFormat = .timestamp
        original.fileExtension = .md
        original.includeMetadata = false

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FileOutputSettings.self, from: data)

        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
        XCTAssertEqual(decoded.outputDirectory, original.outputDirectory)
        XCTAssertEqual(decoded.fileNameFormat, original.fileNameFormat)
        XCTAssertEqual(decoded.fileExtension, original.fileExtension)
        XCTAssertEqual(decoded.includeMetadata, original.includeMetadata)
    }

    // MARK: - Equatable Tests

    /// Equatable が正しく動作することを確認
    func testEquatable() {
        let settings1 = FileOutputSettings.default
        let settings2 = FileOutputSettings.default

        XCTAssertEqual(settings1, settings2)

        var settings3 = FileOutputSettings.default
        settings3.isEnabled = true

        XCTAssertNotEqual(settings1, settings3)
    }

    // MARK: - Enum Tests

    /// FileNameFormat の全ケースをカバー
    func testFileNameFormat_allCases() {
        let allCases = FileOutputSettings.FileNameFormat.allCases

        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.dateTime))
        XCTAssertTrue(allCases.contains(.timestamp))
        XCTAssertTrue(allCases.contains(.sequential))
    }

    /// FileExtension の全ケースをカバー
    func testFileExtension_allCases() {
        let allCases = FileOutputSettings.FileExtension.allCases

        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.txt))
        XCTAssertTrue(allCases.contains(.md))
    }

    /// FileExtension の rawValue が正しいことを確認
    func testFileExtension_rawValues() {
        XCTAssertEqual(FileOutputSettings.FileExtension.txt.rawValue, "txt")
        XCTAssertEqual(FileOutputSettings.FileExtension.md.rawValue, "md")
    }
}
