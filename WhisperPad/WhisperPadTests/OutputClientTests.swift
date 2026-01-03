//
//  OutputClientTests.swift
//  WhisperPadTests
//

import ComposableArchitecture
import XCTest

@testable import WhisperPad

/// OutputClient のテスト
///
/// クリップボード、ファイル出力、通知、完了音の各機能をテストします。
final class OutputClientTests: XCTestCase {
    // MARK: - Interface Tests

    /// testValue の型シグネチャが正しいことを確認
    func testTestValue_hasCorrectSignature() {
        let client = OutputClient.testValue

        // コンパイルが通ればOK（型チェック）
        let _: @Sendable (String) async -> Bool = client.copyToClipboard
        let _: @Sendable (String, FileOutputSettings) async throws -> URL = client.saveToFile
        let _: @Sendable (String, String) async -> Void = client.showNotification
        let _: @Sendable () async -> Void = client.playCompletionSound
        let _: @Sendable () async -> Bool = client.requestNotificationPermission
    }

    /// previewValue の型シグネチャが正しいことを確認
    func testPreviewValue_hasCorrectSignature() {
        let client = OutputClient.previewValue

        // コンパイルが通ればOK（型チェック）
        let _: @Sendable (String) async -> Bool = client.copyToClipboard
        let _: @Sendable (String, FileOutputSettings) async throws -> URL = client.saveToFile
        let _: @Sendable (String, String) async -> Void = client.showNotification
        let _: @Sendable () async -> Void = client.playCompletionSound
        let _: @Sendable () async -> Bool = client.requestNotificationPermission
    }

    // MARK: - Clipboard Tests

    /// copyToClipboard のモック動作を確認
    func testCopyToClipboard_mockBehavior() async {
        var capturedText: String?
        var client = OutputClient.testValue
        client.copyToClipboard = { text in
            capturedText = text
            return true
        }

        let result = await client.copyToClipboard("Test text")

        XCTAssertTrue(result)
        XCTAssertEqual(capturedText, "Test text")
    }

    /// copyToClipboard が失敗した場合を確認
    func testCopyToClipboard_failure() async {
        var client = OutputClient.testValue
        client.copyToClipboard = { _ in
            false
        }

        let result = await client.copyToClipboard("Test text")

        XCTAssertFalse(result)
    }

    // MARK: - File Output Tests

    /// saveToFile が正しいパスにファイルを作成することを確認（モック）
    func testSaveToFile_createsFileAtCorrectPath() async throws {
        var capturedText: String?
        var capturedSettings: FileOutputSettings?

        var client = OutputClient.testValue
        client.saveToFile = { text, settings in
            capturedText = text
            capturedSettings = settings
            return settings.generateFilePath()
        }

        let settings = FileOutputSettings.default
        let result = try await client.saveToFile("Hello World", settings)

        XCTAssertEqual(capturedText, "Hello World")
        XCTAssertEqual(capturedSettings, settings)
        XCTAssertTrue(result.path.contains("WhisperPad"))
    }

    /// saveToFile がエラーをスローした場合、正しく伝播されることを確認
    func testSaveToFile_throwsError_propagatesCorrectly() async {
        let expectedError = OutputError.fileWriteFailed("Test error")

        var client = OutputClient.testValue
        client.saveToFile = { _, _ in
            throw expectedError
        }

        do {
            _ = try await client.saveToFile("Test", FileOutputSettings.default)
            XCTFail("Expected error to be thrown")
        } catch let error as OutputError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// saveToFile がディレクトリ作成エラーをスローすることを確認
    func testSaveToFile_throwsDirectoryCreationError() async {
        let expectedError = OutputError.directoryCreationFailed("Permission denied")

        var client = OutputClient.testValue
        client.saveToFile = { _, _ in
            throw expectedError
        }

        do {
            _ = try await client.saveToFile("Test", FileOutputSettings.default)
            XCTFail("Expected error to be thrown")
        } catch let error as OutputError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Notification Tests

    /// showNotification のモック動作を確認
    func testShowNotification_mockBehavior() async {
        var capturedTitle: String?
        var capturedBody: String?

        var client = OutputClient.testValue
        client.showNotification = { title, body in
            capturedTitle = title
            capturedBody = body
        }

        await client.showNotification("Test Title", "Test Body")

        XCTAssertEqual(capturedTitle, "Test Title")
        XCTAssertEqual(capturedBody, "Test Body")
    }

    // MARK: - Sound Tests

    /// playCompletionSound のモック動作を確認
    func testPlayCompletionSound_mockBehavior() async {
        var soundPlayed = false

        var client = OutputClient.testValue
        client.playCompletionSound = {
            soundPlayed = true
        }

        await client.playCompletionSound()

        XCTAssertTrue(soundPlayed)
    }

    // MARK: - Permission Tests

    /// requestNotificationPermission のモック動作を確認（許可）
    func testRequestNotificationPermission_granted() async {
        var client = OutputClient.testValue
        client.requestNotificationPermission = {
            true
        }

        let result = await client.requestNotificationPermission()

        XCTAssertTrue(result)
    }

    /// requestNotificationPermission のモック動作を確認（拒否）
    func testRequestNotificationPermission_denied() async {
        var client = OutputClient.testValue
        client.requestNotificationPermission = {
            false
        }

        let result = await client.requestNotificationPermission()

        XCTAssertFalse(result)
    }
}

// MARK: - Live Implementation Tests

/// OutputClient のライブ実装テスト
///
/// 実際のファイルシステムを使用したテストです。
final class OutputClientLiveTests: XCTestCase {
    private var testDirectory: URL!

    override func setUp() {
        super.setUp()
        // テスト用の一時ディレクトリを作成
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WhisperPadTests_\(UUID().uuidString)")
    }

    override func tearDown() {
        // テスト用ディレクトリを削除
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    /// ライブ実装でファイルが正しく作成されることを確認
    func testLiveValue_saveToFile_createsFile() async throws {
        let client = OutputClient.liveValue
        var settings = FileOutputSettings.default
        settings.outputDirectory = testDirectory
        settings.fileNameFormat = .timestamp
        settings.includeMetadata = false

        let result = try await client.saveToFile("Test content", settings)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))

        let content = try String(contentsOf: result, encoding: .utf8)
        XCTAssertEqual(content, "Test content")
    }

    /// ライブ実装でメタデータ付きファイルが作成されることを確認
    func testLiveValue_saveToFile_includesMetadata() async throws {
        let client = OutputClient.liveValue
        var settings = FileOutputSettings.default
        settings.outputDirectory = testDirectory
        settings.fileNameFormat = .timestamp
        settings.includeMetadata = true

        let result = try await client.saveToFile("Test content", settings)

        let content = try String(contentsOf: result, encoding: .utf8)
        XCTAssertTrue(content.contains("created:"))
        XCTAssertTrue(content.contains("app: WhisperPad"))
        XCTAssertTrue(content.contains("Test content"))
    }

    /// ライブ実装でマークダウン形式のメタデータが正しく作成されることを確認
    func testLiveValue_saveToFile_markdownMetadata() async throws {
        let client = OutputClient.liveValue
        var settings = FileOutputSettings.default
        settings.outputDirectory = testDirectory
        settings.fileNameFormat = .timestamp
        settings.includeMetadata = true

        let result = try await client.saveToFile("Test content", settings)

        XCTAssertTrue(result.path.hasSuffix(".md"))

        let content = try String(contentsOf: result, encoding: .utf8)
        XCTAssertTrue(content.hasPrefix("---"))
        XCTAssertTrue(content.contains("created:"))
    }

    /// ライブ実装でディレクトリが自動作成されることを確認
    func testLiveValue_saveToFile_createsDirectory() async throws {
        let client = OutputClient.liveValue
        let nestedDirectory = testDirectory.appendingPathComponent("nested/path")

        var settings = FileOutputSettings.default
        settings.outputDirectory = nestedDirectory
        settings.fileNameFormat = .timestamp
        settings.includeMetadata = false

        let result = try await client.saveToFile("Test content", settings)

        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    /// 連番形式でファイルが正しく作成されることを確認
    func testLiveValue_saveToFile_sequentialFormat() async throws {
        let client = OutputClient.liveValue
        var settings = FileOutputSettings.default
        settings.outputDirectory = testDirectory
        settings.fileNameFormat = .sequential
        settings.includeMetadata = false

        // 最初のファイル
        let result1 = try await client.saveToFile("Content 1", settings)
        XCTAssertTrue(result1.lastPathComponent.contains("WhisperPad_001"))

        // 2番目のファイル
        let result2 = try await client.saveToFile("Content 2", settings)
        XCTAssertTrue(result2.lastPathComponent.contains("WhisperPad_002"))
    }
}
