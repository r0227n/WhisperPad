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

    // MARK: - 一時停止/再開テスト

    /// 録音中に一時停止ボタンを押すと paused 状態になることを確認
    func testPauseRecording_setsPausedStatus() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .recording(duration: 10),
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            var client = AudioRecorderClient.testValue
            client.pauseRecording = {}
            $0.audioRecorder = client
            $0.continuousClock = testClock
        }
        store.exhaustivity = .off

        await store.send(.pauseRecordingButtonTapped)
        await store.receive(\.recordingPaused) { state in
            state.status = .paused(duration: 10)
        }
    }

    /// 一時停止中に再開ボタンを押すと recording 状態になることを確認
    func testResumeRecording_setsRecordingStatus() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .paused(duration: 10),
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            var client = AudioRecorderClient.testValue
            client.resumeRecording = {}
            $0.audioRecorder = client
            $0.continuousClock = testClock
        }
        store.exhaustivity = .off

        await store.send(.resumeRecordingButtonTapped)
        await store.receive(\.recordingResumed) { state in
            state.status = .recording(duration: 10)
        }
    }

    /// 一時停止中に録音終了できることを確認
    func testEndRecording_fromPausedState() async {
        let testURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.wav")
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .paused(duration: 10),
                recordingURL: testURL,
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            var client = AudioRecorderClient.testValue
            client.endRecording = {}
            $0.audioRecorder = client
            $0.continuousClock = testClock
        }
        store.exhaustivity = .off

        await store.send(.endRecordingButtonTapped) { state in
            state.status = .ending
        }
    }

    /// idle 状態で一時停止ボタンを押しても何も起こらないことを確認
    func testPauseRecording_whenIdle_doesNothing() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .idle,
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder = .testValue
            $0.continuousClock = testClock
        }

        await store.send(.pauseRecordingButtonTapped)
        // 状態変化がないことを確認（暗黙的に assertNothingReceived）
    }

    /// 録音中でない状態で再開ボタンを押しても何も起こらないことを確認
    func testResumeRecording_whenRecording_doesNothing() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: RecordingFeature.State(
                status: .recording(duration: 10),
                permissionStatus: .granted
            )
        ) {
            RecordingFeature()
        } withDependencies: {
            $0.audioRecorder = .testValue
            $0.continuousClock = testClock
        }

        await store.send(.resumeRecordingButtonTapped)
        // 状態変化がないことを確認（暗黙的に assertNothingReceived）
    }
}
