//
//  StreamingTranscriptionClientTests.swift
//  WhisperPadTests
//

import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// StreamingTranscriptionClient のテスト
@MainActor
final class StreamingTranscriptionClientTests: XCTestCase {
    // MARK: - Test Value Tests

    /// testValue の型シグネチャが正しいことを確認
    func testTestValue_hasCorrectSignature() {
        let client = StreamingTranscriptionClient.testValue

        // コンパイルが通ればOK（型チェック）
        let _: @Sendable (String?) async throws -> Void = client.initialize
        let _: @Sendable ([Float]) async throws -> TranscriptionProgress = client.processChunk
        let _: @Sendable () async throws -> String = client.finalize
        let _: @Sendable () async -> Void = client.reset
    }

    /// testValue の initialize が成功することを確認
    func testInitialize_testValue_succeeds() async throws {
        try await withDependencies {
            $0.streamingTranscription = .testValue
        } operation: {
            @Dependency(\.streamingTranscription) var streamingTranscription
            try await streamingTranscription.initialize(nil)
        }
        // エラーが発生しなければ成功
    }

    /// testValue の processChunk が TranscriptionProgress.empty を返すことを確認
    func testProcessChunk_testValue_returnsEmpty() async throws {
        let progress = try await withDependencies {
            $0.streamingTranscription = .testValue
        } operation: {
            @Dependency(\.streamingTranscription) var streamingTranscription
            return try await streamingTranscription.processChunk([0.1, 0.2, 0.3])
        }

        XCTAssertEqual(progress, TranscriptionProgress.empty)
    }

    /// testValue の finalize が文字列を返すことを確認
    func testFinalize_testValue_returnsText() async throws {
        let text = try await withDependencies {
            $0.streamingTranscription = .testValue
        } operation: {
            @Dependency(\.streamingTranscription) var streamingTranscription
            return try await streamingTranscription.finalize()
        }

        XCTAssertEqual(text, "テスト用の文字起こし結果")
    }

    /// testValue の reset が成功することを確認
    func testReset_testValue_succeeds() async {
        var resetCalled = false

        await withDependencies {
            var client = StreamingTranscriptionClient.testValue
            client.reset = {
                resetCalled = true
            }
            $0.streamingTranscription = client
        } operation: {
            @Dependency(\.streamingTranscription) var streamingTranscription
            await streamingTranscription.reset()
        }

        XCTAssertTrue(resetCalled)
    }

    // MARK: - Custom Mock Tests

    /// カスタムモックで初期化エラーをテスト
    func testInitialize_throwsError_handlesCorrectly() async {
        let expectedError = StreamingTranscriptionError.initializationFailed("Test error")

        do {
            try await withDependencies {
                var client = StreamingTranscriptionClient.testValue
                client.initialize = { _ in
                    throw expectedError
                }
                $0.streamingTranscription = client
            } operation: {
                @Dependency(\.streamingTranscription) var streamingTranscription
                try await streamingTranscription.initialize(nil)
            }
            XCTFail("Should have thrown an error")
        } catch let error as StreamingTranscriptionError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// カスタムモックで処理エラーをテスト
    func testProcessChunk_throwsError_handlesCorrectly() async {
        let expectedError = StreamingTranscriptionError.processingFailed("Processing error")

        do {
            _ = try await withDependencies {
                var client = StreamingTranscriptionClient.testValue
                client.processChunk = { _ in
                    throw expectedError
                }
                $0.streamingTranscription = client
            } operation: {
                @Dependency(\.streamingTranscription) var streamingTranscription
                return try await streamingTranscription.processChunk([0.1])
            }
            XCTFail("Should have thrown an error")
        } catch let error as StreamingTranscriptionError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// 確定ロジックのシミュレーション（2回連続で同じ内容）
    func testProcessChunk_confirmationLogic_simulation() async throws {
        var callCount = 0
        let confirmedText = "確定したテキスト"

        let progress = try await withDependencies {
            var client = StreamingTranscriptionClient.testValue
            client.processChunk = { _ in
                callCount += 1
                if callCount >= 2 {
                    // 2回目以降は確定
                    return TranscriptionProgress(
                        confirmedText: confirmedText,
                        pendingText: "",
                        decodingText: "",
                        tokensPerSecond: 10.0
                    )
                } else {
                    // 1回目は未確定
                    return TranscriptionProgress(
                        confirmedText: "",
                        pendingText: confirmedText,
                        decodingText: "",
                        tokensPerSecond: 10.0
                    )
                }
            }
            $0.streamingTranscription = client
        } operation: {
            @Dependency(\.streamingTranscription) var streamingTranscription
            // 2回呼び出し
            _ = try await streamingTranscription.processChunk([0.1])
            return try await streamingTranscription.processChunk([0.1])
        }

        XCTAssertEqual(progress.confirmedText, confirmedText)
        XCTAssertTrue(progress.pendingText.isEmpty)
    }
}

// MARK: - TranscriptionProgress Tests

extension StreamingTranscriptionClientTests {
    /// TranscriptionProgress.empty の検証
    func testTranscriptionProgress_empty() {
        let empty = TranscriptionProgress.empty

        XCTAssertTrue(empty.confirmedText.isEmpty)
        XCTAssertTrue(empty.pendingText.isEmpty)
        XCTAssertTrue(empty.decodingText.isEmpty)
        XCTAssertEqual(empty.tokensPerSecond, 0)
    }

    /// TranscriptionProgress の等価性テスト
    func testTranscriptionProgress_equality() {
        let progress1 = TranscriptionProgress(
            confirmedText: "test",
            pendingText: "pending",
            decodingText: "decoding",
            tokensPerSecond: 10.0
        )
        let progress2 = TranscriptionProgress(
            confirmedText: "test",
            pendingText: "pending",
            decodingText: "decoding",
            tokensPerSecond: 10.0
        )
        let progress3 = TranscriptionProgress(
            confirmedText: "different",
            pendingText: "pending",
            decodingText: "decoding",
            tokensPerSecond: 10.0
        )

        XCTAssertEqual(progress1, progress2)
        XCTAssertNotEqual(progress1, progress3)
    }
}

// MARK: - StreamingTranscriptionError Tests

extension StreamingTranscriptionClientTests {
    /// StreamingTranscriptionError のローカライズされた説明をテスト
    func testStreamingTranscriptionError_localizedDescription() {
        let initError = StreamingTranscriptionError.initializationFailed("init failed")
        XCTAssertNotNil(initError.errorDescription)
        XCTAssertTrue(initError.errorDescription?.contains("初期化") ?? false)

        let processingError = StreamingTranscriptionError.processingFailed("processing failed")
        XCTAssertNotNil(processingError.errorDescription)
        XCTAssertTrue(processingError.errorDescription?.contains("音声処理") ?? false)

        let bufferError = StreamingTranscriptionError.bufferOverflow
        XCTAssertNotNil(bufferError.errorDescription)
        XCTAssertTrue(bufferError.errorDescription?.contains("オーバーフロー") ?? false)

        let micError = StreamingTranscriptionError.microphonePermissionDenied
        XCTAssertNotNil(micError.errorDescription)
        XCTAssertTrue(micError.errorDescription?.contains("マイク") ?? false)
    }
}
