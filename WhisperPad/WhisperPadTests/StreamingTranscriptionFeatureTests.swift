//
//  StreamingTranscriptionFeatureTests.swift
//  WhisperPadTests
//

import Clocks
import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// StreamingTranscriptionFeature の TCA Reducer テスト
@MainActor
final class StreamingTranscriptionFeatureTests: XCTestCase {
    // MARK: - 開始フローテスト

    /// 開始ボタンタップで初期化が開始されることを確認
    func testStartButtonTapped_beginsInitialization() async {
        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State()
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.startButtonTapped) { state in
            state.status = .initializing
            state.confirmedText = ""
            state.pendingText = ""
            state.decodingText = ""
            state.duration = 0
            state.tokensPerSecond = 0
        }
    }

    /// 初期化完了後に recording 状態に遷移することを確認
    func testInitializationCompleted_transitionsToRecording() async {
        let testClock = TestClock()

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(status: .initializing)
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = testClock
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.initializationCompleted) { state in
            state.status = .recording(duration: 0, tokensPerSecond: 0)
        }
    }

    /// 初期化失敗時に error 状態に遷移することを確認
    func testInitializationFailed_transitionsToError() async {
        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(status: .initializing)
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }

        await store.send(.initializationFailed("Test error")) { state in
            state.status = .error("Test error")
        }
    }

    // MARK: - 停止フローテスト

    /// 停止ボタンタップで processing 状態に遷移することを確認
    func testStopButtonTapped_transitionsToProcessing() async {
        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .recording(duration: 10, tokensPerSecond: 15.0),
                confirmedText: "テスト",
                duration: 10
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.stopButtonTapped) { state in
            state.status = .processing
        }
    }

    /// ファイナライズ完了で completed 状態に遷移することを確認
    func testFinalizationCompleted_transitionsToCompleted() async {
        let finalText = "最終文字起こし結果"

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(status: .processing)
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.finalizationCompleted(finalText)) { state in
            state.status = .completed(text: finalText)
            state.confirmedText = finalText
            state.pendingText = ""
            state.decodingText = ""
        }
    }

    /// ファイナライズ失敗で error 状態に遷移することを確認
    func testFinalizationFailed_transitionsToError() async {
        let errorMessage = "ファイナライズエラー"

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(status: .processing)
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }

        await store.send(.finalizationFailed(errorMessage)) { state in
            state.status = .error(errorMessage)
        }
    }

    // MARK: - キャンセルテスト

    /// キャンセルボタンタップで idle 状態に戻ることを確認
    func testCancelButtonTapped_transitionsToIdle() async {
        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .recording(duration: 5, tokensPerSecond: 10.0),
                confirmedText: "テスト中",
                duration: 5
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.cancelButtonTapped) { state in
            state.status = .idle
            state.confirmedText = ""
            state.pendingText = ""
            state.decodingText = ""
            state.duration = 0
            state.tokensPerSecond = 0
        }

        await store.receive(\.delegate)
    }

    // MARK: - タイマーテスト

    /// timerTick で経過時間が更新されることを確認
    func testTimerTick_updatesDuration() async {
        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .recording(duration: 5, tokensPerSecond: 10.0),
                duration: 5
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }

        await store.send(.timerTick) { state in
            state.duration = 6
            state.status = .recording(duration: 6, tokensPerSecond: 10.0)
        }
    }

    // MARK: - 進捗更新テスト

    /// progressUpdated でテキストが更新されることを確認
    func testProgressUpdated_updatesTextFields() async {
        let progress = TranscriptionProgress(
            confirmedText: "確定テキスト",
            pendingText: "未確定テキスト",
            decodingText: "デコード中",
            tokensPerSecond: 20.5
        )

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .recording(duration: 5, tokensPerSecond: 10.0)
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }

        await store.send(.progressUpdated(progress)) { state in
            state.confirmedText = "確定テキスト"
            state.pendingText = "未確定テキスト"
            state.decodingText = "デコード中"
            state.tokensPerSecond = 20.5
            state.status = .recording(duration: 5, tokensPerSecond: 20.5)
        }
    }

    // MARK: - コピー・保存テスト

    /// copyAndCloseButtonTapped でデリゲートが送信されることを確認
    func testCopyAndCloseButtonTapped_sendsDelegate() async {
        let finalText = "最終結果"

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .completed(text: finalText),
                confirmedText: finalText
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.copyAndCloseButtonTapped)

        // デリゲートアクションが送信されることを確認（2回）
        await store.receive(\.delegate, timeout: .seconds(1))
        await store.receive(\.delegate, timeout: .seconds(1))
    }

    /// saveToFileButtonTapped でファイル保存が呼び出されることを確認
    func testSaveToFileButtonTapped_savesFile() async {
        let finalText = "保存するテキスト"

        let store = TestStore(
            initialState: StreamingTranscriptionFeature.State(
                status: .completed(text: finalText),
                confirmedText: finalText
            )
        ) {
            StreamingTranscriptionFeature()
        } withDependencies: {
            $0.streamingTranscription = .testValue
            $0.streamingAudio = .testValue
            $0.continuousClock = ImmediateClock()
            $0.outputClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.saveToFileButtonTapped)

        // fileSaveCompleted アクションを受信
        await store.receive(\.fileSaveCompleted, timeout: .seconds(1))
    }

    // MARK: - 状態プロパティテスト

    /// displayText が正しく結合されることを確認
    func testDisplayText_combinesAllTextFields() {
        let state = StreamingTranscriptionFeature.State(
            confirmedText: "確定",
            pendingText: "未確定",
            decodingText: "デコード"
        )

        XCTAssertEqual(state.displayText, "確定 未確定 デコード")
    }

    /// displayText が空文字列を除外することを確認
    func testDisplayText_excludesEmptyStrings() {
        let state = StreamingTranscriptionFeature.State(
            confirmedText: "確定",
            pendingText: "",
            decodingText: "デコード"
        )

        XCTAssertEqual(state.displayText, "確定 デコード")
    }

    /// isRecording が正しく判定されることを確認
    func testIsRecording_returnsCorrectValue() {
        var state = StreamingTranscriptionFeature.State(status: .idle)
        XCTAssertFalse(state.isRecording)

        state.status = .recording(duration: 0, tokensPerSecond: 0)
        XCTAssertTrue(state.isRecording)

        state.status = .processing
        XCTAssertFalse(state.isRecording)
    }

    /// isCompleted が正しく判定されることを確認
    func testIsCompleted_returnsCorrectValue() {
        var state = StreamingTranscriptionFeature.State(status: .idle)
        XCTAssertFalse(state.isCompleted)

        state.status = .completed(text: "テスト")
        XCTAssertTrue(state.isCompleted)

        state.status = .recording(duration: 0, tokensPerSecond: 0)
        XCTAssertFalse(state.isCompleted)
    }

    /// isError が正しく判定されることを確認
    func testIsError_returnsCorrectValue() {
        var state = StreamingTranscriptionFeature.State(status: .idle)
        XCTAssertFalse(state.isError)

        state.status = .error("エラー")
        XCTAssertTrue(state.isError)

        state.status = .completed(text: "テスト")
        XCTAssertFalse(state.isError)
    }
}
