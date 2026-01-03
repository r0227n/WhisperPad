//
//  RecordingFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "RecordingFeature")

/// 録音機能の TCA Reducer
///
/// 音声録音のライフサイクル（権限要求、録音開始/停止、タイマー管理）を管理します。
@Reducer
struct RecordingFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 現在の録音ステータス
        var status: Status = .idle
        /// 現在の音声レベル（dB）
        var audioLevel: Float = 0
        /// 録音ファイルの URL
        var recordingURL: URL?
        /// マイク権限ステータス
        var permissionStatus: PermissionStatus = .undetermined
        /// WhisperKit初期化中フラグ
        var whisperKitInitializing: Bool = false

        /// 録音中かどうか
        var isRecording: Bool {
            if case .recording = status { return true }
            return false
        }

        /// 一時停止中かどうか
        var isPaused: Bool {
            if case .paused = status { return true }
            return false
        }

        /// 現在の録音時間（秒）
        var currentDuration: TimeInterval {
            switch status {
            case let .recording(duration):
                duration
            case let .paused(duration):
                duration
            default:
                0
            }
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // ユーザー操作
        /// 録音開始ボタンがタップされた
        case startRecordingButtonTapped
        /// 録音終了ボタンがタップされた
        case endRecordingButtonTapped
        /// 録音キャンセルボタンがタップされた
        case cancelRecordingButtonTapped
        /// 録音一時停止ボタンがタップされた
        case pauseRecordingButtonTapped
        /// 録音再開ボタンがタップされた
        case resumeRecordingButtonTapped

        // 内部アクション
        /// 権限を要求
        case requestPermission
        /// 権限要求の結果
        case permissionResponse(Bool)
        /// WhisperKit準備状態確認
        case checkWhisperKitReady
        /// WhisperKit準備完了
        case whisperKitReady
        /// WhisperKit初期化開始
        case initializeWhisperKit
        /// WhisperKit初期化完了
        case whisperKitInitialized
        /// WhisperKit初期化失敗
        case whisperKitInitFailed(Error)
        /// WhisperKit初期化中に録音が試行された
        case whisperKitInitializingAlertShown
        /// 録音を準備
        case prepareRecording
        /// 録音が開始された
        case recordingStarted(URL)
        /// 録音に失敗
        case recordingFailed(RecordingError)
        /// タイマーのティック
        case timerTick
        /// 音声レベルが更新された
        case audioLevelUpdated(Float)
        /// 録音が完了
        case recordingFinished(Result<URL, RecordingError>)
        /// 録音が一時停止された
        case recordingPaused
        /// 録音が再開された
        case recordingResumed
        /// 録音再開に失敗
        case resumeFailed(RecordingError)
        /// 録音停止結果を受信
        case stopResultReceived(StopResult)

        // デリゲートアクション（親 Reducer への通知）
        /// デリゲートアクション
        case delegate(Delegate)
    }

    // MARK: - Dependencies

    @Dependency(\.audioRecorder) var audioRecorder
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.whisperKitClient) var whisperKitClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startRecordingButtonTapped:
                switch state.permissionStatus {
                case .undetermined:
                    return .send(.requestPermission)
                case .denied:
                    return .send(.delegate(.recordingFailed(.permissionDenied)))
                case .granted:
                    return .send(.checkWhisperKitReady)
                }

            case .requestPermission:
                return .run { send in
                    let granted = await audioRecorder.requestPermission()
                    await send(.permissionResponse(granted))
                }

            case let .permissionResponse(granted):
                state.permissionStatus = granted ? .granted : .denied
                if granted {
                    return .send(.checkWhisperKitReady)
                } else {
                    return .send(.delegate(.recordingFailed(.permissionDenied)))
                }

            case .checkWhisperKitReady:
                return .run { send in
                    let currentState = await whisperKitClient.getState()

                    switch currentState {
                    case .ready:
                        await send(.whisperKitReady)
                    case .initializing:
                        // 既に初期化中 - アラート表示
                        await send(.whisperKitInitializingAlertShown)
                    case .unloaded, .error:
                        // 未初期化 - 初期化を開始
                        await send(.initializeWhisperKit)
                    }
                }

            case .whisperKitReady:
                return .send(.prepareRecording)

            case .initializeWhisperKit:
                state.whisperKitInitializing = true
                return .run { [whisperKitClient, userDefaultsClient] send in
                    do {
                        let settings = await userDefaultsClient.loadSettings()
                        let modelName = settings.transcription.modelName
                        try await whisperKitClient.initialize(modelName)
                        await send(.whisperKitInitialized)
                    } catch {
                        await send(.whisperKitInitFailed(error))
                    }
                }

            case .whisperKitInitialized:
                state.whisperKitInitializing = false
                return .send(.prepareRecording)

            case let .whisperKitInitFailed(error):
                state.whisperKitInitializing = false
                return .send(.delegate(.recordingFailed(.recordingFailed(error.localizedDescription))))

            case .whisperKitInitializingAlertShown:
                // アラートはAppReducerでdelegateを通じて表示
                return .send(.delegate(.whisperKitInitializing))

            case .prepareRecording:
                state.status = .preparing
                // URLではなくidentifierのみを生成
                // URL生成はクライアント内部で行われ、非同期境界での破損を防止
                let identifier = uuid().uuidString

                return .run { [identifier] send in
                    do {
                        // クライアントがURLを生成して返す
                        let recordingURL = try await audioRecorder.startRecording(identifier)
                        await send(.recordingStarted(recordingURL))
                    } catch {
                        let recordingError =
                            (error as? RecordingError)
                                ?? .recordingFailed(error.localizedDescription)
                        await send(.recordingFailed(recordingError))
                    }
                }
                .cancellable(id: "recording")

            case let .recordingStarted(url):
                state.status = .recording(duration: 0)
                state.recordingURL = url
                return .run { send in
                    for await _ in await clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: "timer")

            case .timerTick:
                if case let .recording(duration) = state.status {
                    state.status = .recording(duration: duration + 1)
                }
                return .none

            case .endRecordingButtonTapped:
                // recording または paused 状態で終了可能
                switch state.status {
                case .recording, .paused:
                    break
                default:
                    return .none
                }
                state.status = .ending

                return .merge(
                    .cancel(id: "timer"),
                    .run { send in
                        do {
                            if let result = try await audioRecorder.endRecording() {
                                await send(.stopResultReceived(result))
                            } else {
                                await send(.recordingFailed(.noRecordingURL))
                            }
                        } catch {
                            let recordingError = (error as? RecordingError)
                                ?? .recordingFailed(error.localizedDescription)
                            await send(.recordingFailed(recordingError))
                        }
                    }
                )

            case let .stopResultReceived(result):
                state.status = .idle
                if result.isPartial {
                    return .send(.delegate(.recordingPartialSuccess(
                        url: result.url,
                        usedSegments: result.usedSegments,
                        totalSegments: result.totalSegments
                    )))
                } else {
                    return .send(.delegate(.recordingCompleted(result.url)))
                }

            case .pauseRecordingButtonTapped:
                guard case let .recording(duration) = state.status else { return .none }
                return .merge(
                    .cancel(id: "timer"),
                    .run { [duration] send in
                        await audioRecorder.pauseRecording()
                        await send(.recordingPaused)
                    }
                )

            case .recordingPaused:
                if case let .recording(duration) = state.status {
                    state.status = .paused(duration: duration)
                }
                return .none

            case .resumeRecordingButtonTapped:
                guard case .paused = state.status else { return .none }
                return .run { send in
                    do {
                        try await audioRecorder.resumeRecording()
                        await send(.recordingResumed)
                    } catch {
                        let recordingError = (error as? RecordingError)
                            ?? .recordingFailed(error.localizedDescription)
                        await send(.resumeFailed(recordingError))
                    }
                }

            case .recordingResumed:
                if case let .paused(duration) = state.status {
                    state.status = .recording(duration: duration)
                    // タイマー再開
                    return .run { send in
                        for await _ in await clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: "timer")
                }
                return .none

            case let .resumeFailed(originalError):
                // 再開失敗時は録音を終了
                state.status = .ending
                return .run { send in
                    // 既存のセグメントを取得してみる
                    do {
                        if let result = try await audioRecorder.endRecording() {
                            await send(.stopResultReceived(result))
                        } else {
                            await send(.recordingFailed(originalError))
                        }
                    } catch {
                        await send(.recordingFailed(originalError))
                    }
                }

            case .cancelRecordingButtonTapped:
                state.status = .idle
                state.recordingURL = nil
                return .merge(
                    .cancel(id: "recording"),
                    .cancel(id: "timer"),
                    .run { send in
                        _ = try? await audioRecorder.endRecording()
                        await send(.delegate(.recordingCancelled))
                    }
                )

            case let .recordingFinished(.success(url)):
                state.status = .idle
                return .send(.delegate(.recordingCompleted(url)))

            case let .recordingFinished(.failure(error)):
                state.status = .idle
                state.recordingURL = nil
                return .send(.delegate(.recordingFailed(error)))

            case let .recordingFailed(error):
                state.status = .idle
                state.recordingURL = nil
                return .send(.delegate(.recordingFailed(error)))

            case let .audioLevelUpdated(level):
                state.audioLevel = level
                return .none

            case .delegate:
                // 親 Reducer で処理
                return .none
            }
        }
    }
}

// MARK: - Nested Types

extension RecordingFeature {
    /// 録音ステータス
    enum Status: Equatable, Sendable {
        /// 待機中
        case idle
        /// 準備中
        case preparing
        /// 録音中（経過時間）
        case recording(duration: TimeInterval)
        /// 一時停止中（経過時間）
        case paused(duration: TimeInterval)
        /// 終了処理中
        case ending
    }

    /// マイク権限ステータス
    enum PermissionStatus: Equatable, Sendable {
        /// 未確定（まだ要求していない）
        case undetermined
        /// 許可済み
        case granted
        /// 拒否
        case denied
    }

    /// デリゲートアクション（親 Reducer への通知）
    enum Delegate: Sendable, Equatable {
        /// 録音が完了
        case recordingCompleted(URL)
        /// 録音がキャンセルされた
        case recordingCancelled
        /// 録音に失敗
        case recordingFailed(RecordingError)
        /// 録音が部分的に成功（セグメント結合失敗時）
        case recordingPartialSuccess(url: URL, usedSegments: Int, totalSegments: Int)
        /// WhisperKit初期化中
        case whisperKitInitializing
    }
}
