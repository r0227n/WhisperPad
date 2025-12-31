//
//  StreamingAudioClientTests.swift
//  WhisperPadTests
//

import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// StreamingAudioClient のテスト
@MainActor
final class StreamingAudioClientTests: XCTestCase {
    // MARK: - Test Value Tests

    /// testValue の型シグネチャが正しいことを確認
    func testTestValue_hasCorrectSignature() {
        let client = StreamingAudioClient.testValue

        // コンパイルが通ればOK（型チェック）
        let _: @Sendable () async throws -> AsyncThrowingStream<[Float], Error> = client.startRecording
        let _: @Sendable () async -> Void = client.stopRecording
        let _: @Sendable () async -> Bool = client.isRecording
    }

    /// testValue の startRecording が AsyncThrowingStream を返すことを確認
    func testStartRecording_testValue_returnsStream() async throws {
        var receivedSamples: [[Float]] = []

        let stream = try await withDependencies {
            $0.streamingAudio = .testValue
        } operation: {
            @Dependency(\.streamingAudio) var streamingAudio
            return try await streamingAudio.startRecording()
        }

        for try await samples in stream {
            receivedSamples.append(samples)
        }

        XCTAssertFalse(receivedSamples.isEmpty, "Should receive at least one sample batch")
        XCTAssertEqual(receivedSamples.first?.count, 1600, "Sample batch should have 1600 samples")
    }

    /// testValue の isRecording が false を返すことを確認
    func testIsRecording_testValue_returnsFalse() async {
        let isRecording = await withDependencies {
            $0.streamingAudio = .testValue
        } operation: {
            @Dependency(\.streamingAudio) var streamingAudio
            return await streamingAudio.isRecording()
        }

        XCTAssertFalse(isRecording)
    }

    // MARK: - Custom Mock Tests

    /// カスタムモックでエラーハンドリングをテスト
    func testStartRecording_throwsError_handlesCorrectly() async {
        struct TestError: Error {}

        do {
            _ = try await withDependencies {
                var client = StreamingAudioClient.testValue
                client.startRecording = {
                    throw TestError()
                }
                $0.streamingAudio = client
            } operation: {
                @Dependency(\.streamingAudio) var streamingAudio
                return try await streamingAudio.startRecording()
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    /// カスタムモックで isRecording の状態を確認
    func testIsRecording_customMock_returnsTrue() async {
        let isRecording = await withDependencies {
            var client = StreamingAudioClient.testValue
            client.isRecording = { true }
            $0.streamingAudio = client
        } operation: {
            @Dependency(\.streamingAudio) var streamingAudio
            return await streamingAudio.isRecording()
        }

        XCTAssertTrue(isRecording)
    }

    /// stopRecording が正常に呼び出されることを確認
    func testStopRecording_testValue_succeeds() async {
        var stopCalled = false

        await withDependencies {
            var client = StreamingAudioClient.testValue
            client.stopRecording = {
                stopCalled = true
            }
            $0.streamingAudio = client
        } operation: {
            @Dependency(\.streamingAudio) var streamingAudio
            await streamingAudio.stopRecording()
        }

        XCTAssertTrue(stopCalled)
    }
}
