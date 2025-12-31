//
//  AudioEngineRecorderTests.swift
//  WhisperPadTests
//

import AVFAudio
import XCTest

@testable import WhisperPad

/// AudioRecorder actor の統合テスト
///
/// マイク権限が必要なテストは CI ではスキップされます。
final class AudioRecorderTests: XCTestCase {
    var recorder: AudioRecorder!
    var testIdentifier: String!
    var testURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        recorder = AudioRecorder()
        testIdentifier = UUID().uuidString
        testURL = try AudioRecorderClient.generateRecordingURL(identifier: testIdentifier)
    }

    override func tearDown() async throws {
        await recorder.stop()

        // テストファイルを削除（cachesDirectory を使用）
        if let cacheDir = try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) {
            let testURL = cacheDir
                .appendingPathComponent("com.whisperpad.recordings")
                .appendingPathComponent("whisperpad_\(testIdentifier!).wav")
            try? FileManager.default.removeItem(at: testURL)
        }

        try await super.tearDown()
    }

    // MARK: - 初期状態テスト

    func testInitialState_isNotRecording() async {
        let isRecording = await recorder.isRecording
        let currentTime = await recorder.currentTime
        let currentLevel = await recorder.currentLevel

        XCTAssertFalse(isRecording)
        XCTAssertNil(currentTime)
        XCTAssertNil(currentLevel)
    }

    // MARK: - URL生成テスト

    func testStart_withValidURL() async throws {
        // マイク権限がない場合はスキップ
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        try await recorder.start(url: testURL)

        XCTAssertEqual(testURL.pathExtension, "wav")
        XCTAssertTrue(testURL.lastPathComponent.contains(testIdentifier))

        // URL が有効なパスコンポーネントを持つことを確認
        let directory = testURL.deletingLastPathComponent()
        XCTAssertFalse(directory.path.isEmpty)
        XCTAssertTrue(testURL.pathComponents.count > 1)

        await recorder.stop()
    }

    // MARK: - 録音開始テスト

    func testStart_createsFile() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        try await recorder.start(url: testURL)

        let isRecording = await recorder.isRecording
        XCTAssertTrue(isRecording)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testURL.path))

        await recorder.stop()
    }

    // MARK: - 録音終了テスト

    func testStop_createsValidWAVFile() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        try await recorder.start(url: testURL)

        // 短時間待機
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

        await recorder.stop()

        let isRecording = await recorder.isRecording
        XCTAssertFalse(isRecording)

        // WAV ファイルヘッダー検証
        let data = try Data(contentsOf: testURL)
        XCTAssertGreaterThanOrEqual(data.count, 44)
        XCTAssertEqual(String(data: data[0 ..< 4], encoding: .ascii), "RIFF")
        XCTAssertEqual(String(data: data[8 ..< 12], encoding: .ascii), "WAVE")
    }

    // MARK: - currentTime テスト

    func testCurrentTime_updatesWhileRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        try await recorder.start(url: testURL)

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

        let time = await recorder.currentTime
        XCTAssertNotNil(time)
        XCTAssertGreaterThan(time ?? 0, 0)

        await recorder.stop()
    }

    // MARK: - currentLevel テスト

    func testCurrentLevel_returnsValueWhileRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        try await recorder.start(url: testURL)

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        let level = await recorder.currentLevel
        XCTAssertNotNil(level)

        await recorder.stop()
    }

    // MARK: - 重複開始テスト

    func testStart_stopsExistingRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        let testIdentifier2 = UUID().uuidString
        let testURL2 = try AudioRecorderClient.generateRecordingURL(identifier: testIdentifier2)

        try await recorder.start(url: testURL)
        try await recorder.start(url: testURL2)

        let isRecording = await recorder.isRecording
        XCTAssertTrue(isRecording)

        await recorder.stop()
        try? FileManager.default.removeItem(at: testURL2)
    }

    // MARK: - 空identifier テスト

    func testStart_withEmptyIdentifier_doesNotCrash() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        let emptyURL = try AudioRecorderClient.generateRecordingURL(identifier: "")

        try await recorder.start(url: emptyURL)

        XCTAssertEqual(emptyURL.pathExtension, "wav")

        // deletingLastPathComponent でクラッシュしないことを確認
        let directory = emptyURL.deletingLastPathComponent()
        XCTAssertFalse(directory.path.isEmpty)

        await recorder.stop()
        try? FileManager.default.removeItem(at: emptyURL)
    }
}
