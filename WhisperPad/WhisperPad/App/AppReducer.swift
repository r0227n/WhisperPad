//
//  AppReducer.swift
//  WhisperPad
//

import ComposableArchitecture

/// アプリケーションのステータス
enum AppStatus: Equatable, Sendable {
    /// 待機中
    case idle
    /// 録音中
    case recording
    /// 文字起こし中
    case transcribing
    /// 完了
    case completed
    /// エラー
    case error(String)
}

/// アプリケーション全体の状態を管理する TCA Reducer
///
/// アプリのステータス（idle, recording, transcribing, completed, error）を管理し、
/// 各状態に応じたアクションを処理します。
@Reducer
struct AppReducer {
    // MARK: - State

    /// アプリケーションの状態
    @ObservableState
    struct State: Equatable {
        /// 現在のアプリステータス
        var appStatus: AppStatus = .idle

        /// 最後の文字起こし結果
        var lastTranscription: String?
    }

    // MARK: - Action

    /// アプリケーションのアクション
    enum Action {
        /// 録音を開始
        case startRecording
        /// 録音を停止
        case stopRecording
        /// 文字起こしが完了
        case transcriptionCompleted(String)
        /// エラーが発生
        case errorOccurred(String)
        /// 待機状態にリセット
        case resetToIdle
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startRecording:
                state.appStatus = .recording
                return .cancel(id: "autoReset")

            case .stopRecording:
                state.appStatus = .transcribing
                return .none

            case let .transcriptionCompleted(text):
                state.appStatus = .completed
                state.lastTranscription = text
                return .run { send in
                    try await clock.sleep(for: .seconds(3))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case let .errorOccurred(message):
                state.appStatus = .error(message)
                return .run { send in
                    try await clock.sleep(for: .seconds(5))
                    await send(.resetToIdle)
                }
                .cancellable(id: "autoReset")

            case .resetToIdle:
                state.appStatus = .idle
                return .none
            }
        }
    }
}
