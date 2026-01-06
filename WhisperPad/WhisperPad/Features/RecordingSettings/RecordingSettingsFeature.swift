//
//  RecordingSettingsFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

// MARK: - RecordingSettings Feature

/// 録音設定機能の TCA Reducer
///
/// 録音設定（入力デバイス、無音検出）および出力設定（クリップボード、ファイル保存）を管理します。
@Reducer
struct RecordingSettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 録音設定
        var recording: RecordingSettings

        /// ファイル出力設定
        var output: FileOutputSettings

        /// 利用可能な入力デバイス一覧
        var availableInputDevices: [AudioInputDevice] = []

        /// 現在の音声レベル（dB）
        var currentAudioLevel: Float = -60.0

        /// 音声レベル監視中かどうか
        var isMonitoringAudio: Bool = false

        init(
            recording: RecordingSettings = .default,
            output: FileOutputSettings = .default,
            availableInputDevices: [AudioInputDevice] = [],
            currentAudioLevel: Float = -60.0,
            isMonitoringAudio: Bool = false
        ) {
            self.recording = recording
            self.output = output
            self.availableInputDevices = availableInputDevices
            self.currentAudioLevel = currentAudioLevel
            self.isMonitoringAudio = isMonitoringAudio
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Settings Updates

        /// 録音設定を更新
        case updateRecordingSettings(RecordingSettings)
        /// 出力設定を更新
        case updateOutputSettings(FileOutputSettings)
        /// 出力ディレクトリのブックマークが作成された
        case outputBookmarkCreated(Data)
        /// 出力ディレクトリのブックマークが解決された
        case outputDirectoryResolved(URL)

        // MARK: - Input Devices

        /// 入力デバイス一覧を取得
        case fetchInputDevices
        /// 入力デバイス一覧取得完了
        case inputDevicesResponse([AudioInputDevice])

        // MARK: - Audio Level Monitoring

        /// 音声レベル監視をトグル
        case toggleAudioMonitoring
        /// 音声レベル監視を開始
        case startAudioLevelObservation
        /// 音声レベル監視を停止
        case stopAudioLevelObservation
        /// 音声レベルが更新された
        case audioLevelUpdated(Float)

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// 録音設定が変更された
            case recordingSettingsChanged(RecordingSettings)
            /// 出力設定が変更された
            case outputSettingsChanged(FileOutputSettings)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.audioRecorder) var audioRecorder
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .updateRecordingSettings(recording):
                state.recording = recording
                return .send(.delegate(.recordingSettingsChanged(recording)))

            case let .updateOutputSettings(output):
                let previousDirectory = state.output.outputDirectory
                state.output = output

                // 出力ディレクトリが変更された場合、ブックマークを作成
                if output.outputDirectory != previousDirectory {
                    return .run { [userDefaultsClient] send in
                        do {
                            let bookmarkData = try await userDefaultsClient.createBookmark(
                                output.outputDirectory
                            )
                            await send(.outputBookmarkCreated(bookmarkData))
                        } catch {
                            // ブックマーク作成失敗（ログのみ、デフォルトパスでは不要）
                        }
                        await send(.delegate(.outputSettingsChanged(output)))
                    }
                }

                return .send(.delegate(.outputSettingsChanged(output)))

            case let .outputBookmarkCreated(bookmarkData):
                state.output.outputBookmarkData = bookmarkData
                return .none

            case let .outputDirectoryResolved(url):
                state.output.outputDirectory = url
                return .none

            case .fetchInputDevices:
                return .run { send in
                    let devices = await audioRecorder.fetchInputDevices()
                    await send(.inputDevicesResponse(devices))
                }

            case let .inputDevicesResponse(devices):
                state.availableInputDevices = devices
                return .none

            case .toggleAudioMonitoring:
                if state.isMonitoringAudio {
                    return .send(.stopAudioLevelObservation)
                } else {
                    return .send(.startAudioLevelObservation)
                }

            case .startAudioLevelObservation:
                state.isMonitoringAudio = true
                return .run { [audioRecorder] send in
                    do {
                        // モニタリングを開始
                        try await audioRecorder.startMonitoring()
                    } catch {
                        // モニタリング開始失敗時はログに記録
                        // observeAudioLevel()はデフォルト値(-60.0)を返す
                        Logger(subsystem: "com.whisperpad", category: "RecordingSettingsFeature")
                            .warning("Failed to start audio monitoring: \(error.localizedDescription)")
                    }

                    // モニタリングの成否に関わらず、レベル監視は継続
                    for await level in await audioRecorder.observeAudioLevel() {
                        await send(.audioLevelUpdated(level))
                    }
                }
                .cancellable(id: "audioLevelObservation")

            case .stopAudioLevelObservation:
                state.isMonitoringAudio = false
                state.currentAudioLevel = -60.0
                return .run { [audioRecorder] _ in
                    // モニタリングを停止
                    await audioRecorder.stopMonitoring()
                }
                .concatenate(with: .cancel(id: "audioLevelObservation"))

            case let .audioLevelUpdated(level):
                state.currentAudioLevel = level
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
