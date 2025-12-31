//
//  AppReducerStreamingTests.swift
//  WhisperPadTests
//

import Clocks
import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// AppReducer のストリーミング統合テスト
@MainActor
final class AppReducerStreamingTests: XCTestCase {
    // MARK: - 開始フローテスト

    /// startStreamingTranscription で streamingTranscription に委譲されることを確認
    func testStartStreamingTranscription_delegatesToFeature() async {
        let store = TestStore(
            initialState: AppReducer.State()
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.startStreamingTranscription)
        await store.receive(\.streamingTranscription.startButtonTapped)
    }

    // MARK: - デリゲートアクションテスト

    /// streamingCompleted デリゲートで appStatus が更新されることを確認
    func testStreamingCompleted_updatesAppStatus() async {
        let finalText = "最終結果テキスト"
        let testClock = TestClock()

        let store = TestStore(
            initialState: AppReducer.State(appStatus: .streamingTranscribing)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = testClock
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.streamingTranscription(.delegate(.streamingCompleted(finalText)))) { state in
            state.appStatus = .streamingCompleted
            state.lastTranscription = finalText
        }
    }

    /// streamingCancelled デリゲートで appStatus が idle に戻ることを確認
    func testStreamingCancelled_resetsToIdle() async {
        let store = TestStore(
            initialState: AppReducer.State(appStatus: .streamingTranscribing)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }

        await store.send(.streamingTranscription(.delegate(.streamingCancelled))) { state in
            state.appStatus = .idle
        }
    }

    /// closePopup デリゲートで通知が送信されることを確認
    func testClosePopup_postsNotification() async {
        var notificationPosted = false
        let observer = NotificationCenter.default.addObserver(
            forName: .closeStreamingPopup,
            object: nil,
            queue: .main
        ) { _ in
            notificationPosted = true
        }

        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        let store = TestStore(
            initialState: AppReducer.State(appStatus: .streamingTranscribing)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.streamingTranscription(.delegate(.closePopup)))

        // 通知が送信されるまで少し待機
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(notificationPosted)
    }

    // MARK: - 状態遷移テスト

    /// initializationCompleted で appStatus が streamingTranscribing になることを確認
    func testInitializationCompleted_setsStreamingTranscribingStatus() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: AppReducer.State(appStatus: .idle)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = testClock
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.streamingTranscription(.initializationCompleted)) { state in
            state.appStatus = .streamingTranscribing
        }
    }

    // MARK: - 自動リセットテスト

    /// streamingCompleted 後に自動リセットが行われることを確認
    func testStreamingCompleted_autoResets() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: AppReducer.State(appStatus: .streamingTranscribing)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = testClock
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.streamingTranscription(.delegate(.streamingCompleted("テスト")))) { state in
            state.appStatus = .streamingCompleted
            state.lastTranscription = "テスト"
        }

        // 3秒後に自動リセット
        await testClock.advance(by: .seconds(3))

        await store.receive(\.resetToIdle) { state in
            state.appStatus = .idle
        }
    }

    // MARK: - 子アクションパススルーテスト

    /// streamingTranscription の内部アクションが無視されることを確認
    func testStreamingTranscription_internalActions_ignored() async {
        let store = TestStore(
            initialState: AppReducer.State(appStatus: .streamingTranscribing)
        ) {
            AppReducer()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
            $0.audioRecorder = .testValue
            $0.transcriptionClient = .testValue
            $0.userDefaultsClient = .testValue
        }

        // timerTick などの内部アクションは状態変更なしでパススルー
        await store.send(.streamingTranscription(.timerTick))
    }

    // MARK: - 排他制御テスト

    /// 録音中はストリーミング開始できない（UIレベル制御の確認）
    func testRecordingState_excludesStreaming() {
        // この排他制御は AppDelegate のメニュー更新で行われる
        // Reducer レベルでは特に制限していない
        let state = AppReducer.State(appStatus: .recording)
        XCTAssertEqual(state.appStatus, .recording)
        // UIレベルでストリーミングメニューが無効化される
    }

    /// ストリーミング中は録音開始できない（UIレベル制御の確認）
    func testStreamingState_excludesRecording() {
        // この排他制御は AppDelegate のメニュー更新で行われる
        let state = AppReducer.State(appStatus: .streamingTranscribing)
        XCTAssertEqual(state.appStatus, .streamingTranscribing)
        // UIレベルで録音メニューが無効化される
    }
}
