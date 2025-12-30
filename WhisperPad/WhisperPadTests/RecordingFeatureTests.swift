//
//  RecordingFeatureTests.swift
//  WhisperPadTests
//

import Clocks
import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// RecordingFeature の TCA Reducer テスト
///
/// URL の String キャプチャと再作成が正しく動作することを検証します。
@MainActor
final class RecordingFeatureTests: XCTestCase {
    // MARK: - 状態遷移テスト

    /// recordingStarted アクション受信後に status が .recording になることを確認
    func testRecordingStarted_setsRecordingStatus() async {
        let testUUID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let expectedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whisperpad_\(testUUID.uuidString)")
            .appendingPathExtension("wav")
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .preparing,
                recordingURL: expectedURL,
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder = .testValue
            $0.continuousClock = testClock
        }
        store.exhaustivity = .off

        await store.send(.recordingStarted(expectedURL)) { state in
            state.status = .recording(duration: 0)
            state.recordingURL = expectedURL
        }
    }

    // MARK: - エラーハンドリングテスト

    /// 録音失敗時に正しくエラーが伝播されることを確認
    func testPrepareRecording_handlesRecordingError() async {
        let testUUID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let expectedError = RecordingError.recorderStartFailed("Test error")
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(permissionStatus: .granted)
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder.startRecording = { _ -> URL in
                throw expectedError
            }
            $0.uuid = .constant(testUUID)
            $0.continuousClock = testClock
        }

        await store.send(.startRecordingButtonTapped)
        await store.receive(\.prepareRecording) { state in
            state.status = .preparing
        }
        await store.receive(\.recordingFailed) { state in
            state.status = .idle
            state.recordingURL = nil
        }
        await store.receive(\.delegate)
    }

    /// クライアントがエラーをスローした場合、recordingFailed に遷移することを確認
    func testPrepareRecording_clientThrowsError_transitionsToFailed() async {
        let testUUID = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        let expectedError = RecordingError.audioFileCreationFailed("Test error")
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(permissionStatus: .granted)
        ) {
            RecordingFeature()
        } withDependencies: {
            var client = AudioRecorderClient.testValue
            client.startRecording = { _ -> URL in
                throw expectedError
            }
            $0.audioRecorder = client
            $0.uuid = .constant(testUUID)
            $0.continuousClock = testClock
        }

        await store.send(.startRecordingButtonTapped)
        await store.receive(\.prepareRecording) { state in
            state.status = .preparing
        }
        await store.receive(\.recordingFailed) { state in
            state.status = .idle
            state.recordingURL = nil
        }
        await store.receive(\.delegate)
    }
}
