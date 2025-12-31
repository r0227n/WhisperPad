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
        _ = try? await recorder.stop()

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

            // セグメントファイルも削除
            let segmentURL = cacheDir
                .appendingPathComponent("com.whisperpad.recordings")
                .appendingPathComponent("whisperpad_\(testIdentifier!)_segment0.wav")
            try? FileManager.default.removeItem(at: segmentURL)
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

    func testStart_withValidIdentifier() async throws {
        // マイク権限がない場合はスキップ
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        let resultURL = try await recorder.start(identifier: testIdentifier)

        XCTAssertEqual(resultURL.pathExtension, "wav")
        XCTAssertTrue(resultURL.lastPathComponent.contains(testIdentifier))

        // URL が有効なパスコンポーネントを持つことを確認
        let directory = resultURL.deletingLastPathComponent()
        XCTAssertFalse(directory.path.isEmpty)
        XCTAssertTrue(resultURL.pathComponents.count > 1)

        _ = try await recorder.stop()
    }

    // MARK: - 録音開始テスト

    func testStart_createsFile() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        _ = try await recorder.start(identifier: testIdentifier)

        let isRecording = await recorder.isRecording
        XCTAssertTrue(isRecording)

        // セグメントファイルが作成されることを確認
        let segmentURL = try AudioRecorderClient.generateRecordingURL(identifier: testIdentifier)
            .deletingLastPathComponent()
            .appendingPathComponent("whisperpad_\(testIdentifier!)_segment0.wav")
        XCTAssertTrue(FileManager.default.fileExists(atPath: segmentURL.path))

        _ = try await recorder.stop()
    }

    // MARK: - 録音終了テスト

    func testStop_createsValidWAVFile() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        _ = try await recorder.start(identifier: testIdentifier)

        // 短時間待機
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

        let result = try await recorder.stop()

        let isRecording = await recorder.isRecording
        XCTAssertFalse(isRecording)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.isPartial)

        // WAV ファイルヘッダー検証
        let data = try Data(contentsOf: result!.url)
        XCTAssertGreaterThanOrEqual(data.count, 44)
        XCTAssertEqual(String(data: data[0 ..< 4], encoding: .ascii), "RIFF")
        XCTAssertEqual(String(data: data[8 ..< 12], encoding: .ascii), "WAVE")
    }

    // MARK: - currentTime テスト

    func testCurrentTime_updatesWhileRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        _ = try await recorder.start(identifier: testIdentifier)

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

        let time = await recorder.currentTime
        XCTAssertNotNil(time)
        XCTAssertGreaterThan(time ?? 0, 0)

        _ = try await recorder.stop()
    }

    // MARK: - currentLevel テスト

    func testCurrentLevel_returnsValueWhileRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        _ = try await recorder.start(identifier: testIdentifier)

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        let level = await recorder.currentLevel
        XCTAssertNotNil(level)

        _ = try await recorder.stop()
    }

    // MARK: - 重複開始テスト

    func testStart_stopsExistingRecording() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        let testIdentifier2 = UUID().uuidString
        let testURL2 = try AudioRecorderClient.generateRecordingURL(identifier: testIdentifier2)

        _ = try await recorder.start(identifier: testIdentifier)
        _ = try await recorder.start(identifier: testIdentifier2)

        let isRecording = await recorder.isRecording
        XCTAssertTrue(isRecording)

        _ = try await recorder.stop()
        try? FileManager.default.removeItem(at: testURL2)
    }

    // MARK: - 空identifier テスト

    func testStart_withEmptyIdentifier_throwsError() async throws {
        guard await AudioRecorder.requestPermission() else {
            throw XCTSkip("マイク権限が必要")
        }

        // 空の identifier は AudioRecorderClient.generateRecordingURL でエラーになる
        do {
            _ = try AudioRecorderClient.generateRecordingURL(identifier: "")
            XCTFail("Expected error to be thrown")
        } catch {
            // エラーがスローされることを確認
            XCTAssertTrue(error is RecordingError)
        }
    }
}
