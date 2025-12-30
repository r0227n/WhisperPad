//
//  AudioRecorderIntegrationTests.swift
//  WhisperPadTests
//

import Clocks
import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// AudioRecorderClient と AudioRecorder の統合テスト
final class AudioRecorderIntegrationTests: XCTestCase {
    // MARK: - liveValue テスト

    /// AudioRecorderClient.liveValue が正しく構成されていることを確認
    func testLiveValue_isConfigured() {
        let client = AudioRecorderClient.liveValue
        XCTAssertNotNil(client.requestPermission)
        XCTAssertNotNil(client.startRecording)
        XCTAssertNotNil(client.stopRecording)
        XCTAssertNotNil(client.currentTime)
        XCTAssertNotNil(client.currentLevel)
    }

    /// liveValue が新しいAPIシグネチャを持つことを確認
    /// startRecording は identifier (String) を受け取り URL を返す
    func testLiveValue_hasCorrectSignature() async throws {
        let client = AudioRecorderClient.liveValue

        // startRecording は identifier を受け取り URL を返す
        // コンパイルが通ればOK（型チェック）
        let _: @Sendable (String) async throws -> URL = client.startRecording
    }

    // MARK: - RecordingFeature 統合テスト

    /// RecordingFeature の初期状態を確認
    @MainActor
    func testRecordingFeature_initialState() async {
        let store = TestStore(
            initialState: RecordingFeature.State()
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder = .testValue
        }

        XCTAssertEqual(store.state.status, .idle)
        XCTAssertFalse(store.state.isRecording)
        XCTAssertEqual(store.state.currentDuration, 0)
    }

    /// 権限拒否時のフローを確認
    @MainActor
    func testRecordingFeature_permissionDenied() async {
        let store = TestStore(
            initialState: RecordingFeature.State()
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder.requestPermission = { false }
        }

        await store.send(.startRecordingButtonTapped)
        await store.receive(\.requestPermission)
        await store.receive(\.permissionResponse) {
            $0.permissionStatus = .denied
        }
        await store.receive(\.delegate)
    }
}
