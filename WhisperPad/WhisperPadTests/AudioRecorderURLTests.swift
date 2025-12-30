//
//  AudioRecorderURLTests.swift
//  WhisperPadTests
//

import XCTest

@testable import WhisperPad

/// AudioRecorderClient.generateRecordingURL の単体テスト
///
/// URL生成ロジックのテストを行います。マイク権限は不要です。
final class AudioRecorderURLTests: XCTestCase {
    // MARK: - Valid Identifier Tests

    /// 正常なUUIDでURL生成
    func testGenerateRecordingURL_withValidIdentifier() throws {
        let identifier = UUID().uuidString

        let url = try AudioRecorderClient.generateRecordingURL(identifier: identifier)

        XCTAssertEqual(url.pathExtension, "wav")
        XCTAssertTrue(url.lastPathComponent.contains(identifier))
    }

    /// 空のidentifierでURL生成
    func testGenerateRecordingURL_withEmptyIdentifier() throws {
        let url = try AudioRecorderClient.generateRecordingURL(identifier: "")

        XCTAssertEqual(url.pathExtension, "wav")
        XCTAssertEqual(url.lastPathComponent, "whisperpad_.wav")
    }

    /// 特殊文字を含むidentifierでURL生成
    func testGenerateRecordingURL_withSpecialCharacters() throws {
        let identifier = "test-123_abc"

        let url = try AudioRecorderClient.generateRecordingURL(identifier: identifier)

        XCTAssertEqual(url.pathExtension, "wav")
        XCTAssertTrue(url.lastPathComponent.contains(identifier))
    }

    // MARK: - Path Structure Tests

    /// パス構造の検証
    func testGenerateRecordingURL_pathStructure() throws {
        let identifier = "test-id"

        let url = try AudioRecorderClient.generateRecordingURL(identifier: identifier)

        // パスコンポーネントが正しい構造を持つことを確認
        XCTAssertTrue(url.pathComponents.count > 2)
        XCTAssertTrue(url.path.contains("com.whisperpad.recordings"))
        XCTAssertTrue(url.path.contains("whisperpad_test-id.wav"))
    }

    /// ファイル拡張子が .wav であることを確認
    func testGenerateRecordingURL_fileExtension() throws {
        let identifier = "any-id"

        let url = try AudioRecorderClient.generateRecordingURL(identifier: identifier)

        XCTAssertEqual(url.pathExtension, "wav")
    }

    // MARK: - Directory Tests

    /// 生成されたURLのディレクトリが有効であることを確認
    func testGenerateRecordingURL_hasValidDirectory() throws {
        let identifier = UUID().uuidString

        let url = try AudioRecorderClient.generateRecordingURL(identifier: identifier)
        let directory = url.deletingLastPathComponent()

        XCTAssertFalse(directory.path.isEmpty)
        XCTAssertTrue(directory.path.contains("Caches") || directory.path.contains("cache"))
    }

    /// 複数回呼び出しても一貫したパス構造
    func testGenerateRecordingURL_consistentPathStructure() throws {
        let identifier = "consistent-test"

        let url1 = try AudioRecorderClient.generateRecordingURL(identifier: identifier)
        let url2 = try AudioRecorderClient.generateRecordingURL(identifier: identifier)

        XCTAssertEqual(url1, url2)
    }
}
