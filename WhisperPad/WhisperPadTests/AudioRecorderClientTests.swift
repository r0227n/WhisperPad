//
//  AudioRecorderClientTests.swift
//  WhisperPadTests
//

import ComposableArchitecture
import XCTest

@testable import WhisperPad

/// AudioRecorderClient の新API テスト
///
/// 新しいインターフェース（startRecording が identifier を受け取り URL を返す）の
/// 動作を検証します。
final class AudioRecorderClientTests: XCTestCase {
    // MARK: - Interface Tests (新API)

    /// startRecording がエラーをスローした場合、正しく伝播されることを確認
    func testStartRecording_throwsError_propagatesCorrectly() async {
        let expectedError = RecordingError.recorderStartFailed("Test error")

        var client = AudioRecorderClient.testValue
        client.startRecording = { _ in
            throw expectedError
        }

        do {
            _ = try await client.startRecording("test-id")
            XCTFail("Expected error to be thrown")
        } catch let error as RecordingError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// testValue の型シグネチャが正しいことを確認
    func testTestValue_hasCorrectSignature() {
        let client = AudioRecorderClient.testValue

        // コンパイルが通ればOK（型チェック）
        let _: @Sendable (String) async throws -> URL = client.startRecording
        let _: @Sendable () async -> Bool = client.requestPermission
        let _: @Sendable () async -> Void = client.stopRecording
        let _: @Sendable () async -> TimeInterval? = client.currentTime
        let _: @Sendable () async -> Float? = client.currentLevel
    }
}
