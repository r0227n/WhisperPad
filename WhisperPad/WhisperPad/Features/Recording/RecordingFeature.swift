//
//  RecordingFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation

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

        /// 録音中かどうか
        var isRecording: Bool {
            if case .recording = status { return true }
            return false
        }

        /// 現在の録音時間（秒）
        var currentDuration: TimeInterval {
            if case let .recording(duration) = status {
                return duration
            }
            return 0
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // ユーザー操作
        /// 録音開始ボタンがタップされた
        case startRecordingButtonTapped
        /// 録音停止ボタンがタップされた
        case stopRecordingButtonTapped
        /// 録音キャンセルボタンがタップされた
        case cancelRecordingButtonTapped

        // 内部アクション
        /// 権限を要求
        case requestPermission
        /// 権限要求の結果
        case permissionResponse(Bool)
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

        // デリゲートアクション（親 Reducer への通知）
        /// デリゲートアクション
        case delegate(Delegate)
    }

    // MARK: - Dependencies

    @Dependency(\.audioRecorder) var audioRecorder
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid

    /// 最大録音時間（秒）
    private let maxRecordingDuration: TimeInterval = 60

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
                    return .send(.prepareRecording)
                }

            case .requestPermission:
                return .run { send in
                    let granted = await audioRecorder.requestPermission()
                    await send(.permissionResponse(granted))
                }

            case let .permissionResponse(granted):
                state.permissionStatus = granted ? .granted : .denied
                if granted {
                    return .send(.prepareRecording)
                } else {
                    return .send(.delegate(.recordingFailed(.permissionDenied)))
                }

            case .prepareRecording:
                state.status = .preparing
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("whisperpad_\(uuid().uuidString)")
                    .appendingPathExtension("wav")
                state.recordingURL = url

                // URL ではなく String (パス) をキャプチャして非同期コンテキスト間での破損を防止
                //
                // TCA のエフェクトシステムでは @Sendable クロージャの制約により、
                // 参照型の内部状態が破損するリスクがあります。
                // Swift 5.5 以降 URL は Sendable に準拠していますが、
                // TCA のベストプラクティスとして値型（String）経由での受け渡しを使用します。
                //
                // 参考: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/
                let urlPath = url.path

                return .run { [urlPath] send in
                    do {
                        // String から URL を再作成（値型からの変換なので安全）
                        let recordingURL = URL(fileURLWithPath: urlPath)
                        try await audioRecorder.startRecording(recordingURL)
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
                    let newDuration = duration + 1
                    state.status = .recording(duration: newDuration)
                    // 最大録音時間に達した場合は自動停止
                    if newDuration >= maxRecordingDuration {
                        return .send(.stopRecordingButtonTapped)
                    }
                }
                return .none

            case .stopRecordingButtonTapped:
                guard case .recording = state.status else { return .none }
                state.status = .stopping

                return .merge(
                    .cancel(id: "timer"),
                    .run { [url = state.recordingURL] send in
                        await audioRecorder.stopRecording()
                        if let url {
                            await send(.recordingFinished(.success(url)))
                        } else {
                            await send(.recordingFailed(.noRecordingURL))
                        }
                    }
                )

            case .cancelRecordingButtonTapped:
                state.status = .idle
                state.recordingURL = nil
                return .merge(
                    .cancel(id: "recording"),
                    .cancel(id: "timer"),
                    .run { send in
                        await audioRecorder.stopRecording()
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
        /// 停止処理中
        case stopping
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
    }
}
