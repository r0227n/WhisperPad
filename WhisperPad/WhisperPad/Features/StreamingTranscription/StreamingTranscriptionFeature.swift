//
//  StreamingTranscriptionFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "StreamingTranscriptionFeature")

/// ストリーミング文字起こし機能の TCA Reducer
///
/// リアルタイム音声入力から文字起こしを行うライフサイクル
/// （初期化、録音開始/停止、文字起こし処理、結果出力）を管理します。
@Reducer
struct StreamingTranscriptionFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 現在のストリーミングステータス
        var status: StreamingStatus = .idle

        /// 確定済みテキスト（変更されない）
        var confirmedText: String = ""

        /// 未確定テキスト（確定待ち）
        var pendingText: String = ""

        /// デコード中のテキスト（プレビュー）
        var decodingText: String = ""

        /// 録音経過時間（秒）
        var duration: TimeInterval = 0

        /// 処理速度（トークン/秒）
        var tokensPerSecond: Double = 0

        /// デコード中プレビューを表示するかどうか
        var showDecodingPreview: Bool = true

        /// 全テキスト（表示用）
        var displayText: String {
            [confirmedText, pendingText, decodingText]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        /// 録音中かどうか
        var isRecording: Bool {
            if case .recording = status { return true }
            return false
        }

        /// 完了状態かどうか
        var isCompleted: Bool {
            if case .completed = status { return true }
            return false
        }

        /// エラー状態かどうか
        var isError: Bool {
            if case .error = status { return true }
            return false
        }

        /// キャンセル確認ダイアログを表示するか
        var showCancelConfirmation: Bool = false
    }

    // MARK: - Action

    enum Action: Sendable, BindableAction {
        // ユーザー操作
        /// 開始ボタンがタップされた
        case startButtonTapped
        /// 停止ボタンがタップされた
        case stopButtonTapped
        /// ✕ボタンがタップされた（条件分岐用）
        case closeButtonTapped
        /// キャンセルボタンがタップされた（内部用：実際のキャンセル処理）
        case cancelButtonTapped
        /// キャンセル確認ダイアログで「中止して閉じる」が選択された
        case cancelConfirmationConfirmed
        /// キャンセル確認ダイアログで「続ける」が選択された
        case cancelConfirmationDismissed
        /// 「コピーして閉じる」ボタンがタップされた
        case copyAndCloseButtonTapped
        /// 「ファイル保存」ボタンがタップされた
        case saveToFileButtonTapped
        /// Binding action
        case binding(BindingAction<State>)

        // 内部アクション
        /// 初期化が完了した
        case initializationCompleted
        /// プレビュー表示設定を更新
        case updateShowDecodingPreview(Bool)
        /// 初期化に失敗した
        case initializationFailed(String)
        /// 進捗が更新された
        case progressUpdated(TranscriptionProgress)
        /// 音声チャンクを受信した
        case audioChunkReceived([Float])
        /// タイマーのティック
        case timerTick
        /// ファイナライズが完了した
        case finalizationCompleted(String)
        /// ファイナライズに失敗した
        case finalizationFailed(String)
        /// ファイル保存が完了した
        case fileSaveCompleted(URL)
        /// ファイル保存に失敗した
        case fileSaveFailed(String)

        // デリゲートアクション（親Reducerへの通知）
        case delegate(Delegate)
    }

    /// デリゲートアクション
    enum Delegate: Sendable, Equatable {
        /// ストリーミングが完了した
        case streamingCompleted(String)
        /// ストリーミングがキャンセルされた
        case streamingCancelled
        /// ポップアップを閉じる
        case closePopup
    }

    // MARK: - CancelID

    private enum CancelID {
        static let audioStream = "streaming-audio"
        static let timer = "streaming-timer"
        static let initialization = "streaming-initialization"
    }

    // MARK: - Dependencies

    @Dependency(\.streamingAudio) var streamingAudio
    @Dependency(\.streamingTranscription) var streamingTranscription
    @Dependency(\.continuousClock) var clock
    @Dependency(\.outputClient) var outputClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.whisperKitClient) var whisperKitClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // MARK: - ユーザー操作

            case .startButtonTapped:
                guard state.status == .idle else { return .none }
                state.status = .initializing
                state.confirmedText = ""
                state.pendingText = ""
                state.decodingText = ""
                state.duration = 0
                state.tokensPerSecond = 0

                return .run { [userDefaultsClient, whisperKitClient, streamingTranscription] send in
                    // 設定を読み込んでプレビュー表示設定を反映
                    let settings = await userDefaultsClient.loadSettings()
                    await send(.updateShowDecodingPreview(settings.streaming.showDecodingPreview))
                    do {
                        // WhisperKitManager が ready なら即座に初期化完了
                        let isReady = await whisperKitClient.isReady()
                        if isReady {
                            // 状態リセットのみ行う
                            try await streamingTranscription.initialize(nil)
                            await send(.initializationCompleted)
                        } else {
                            // フォールバック: WhisperKit の初期化を実行
                            try await streamingTranscription.initialize(nil)
                            await send(.initializationCompleted)
                        }
                    } catch {
                        let message = (error as? StreamingTranscriptionError)?.errorDescription
                            ?? error.localizedDescription
                        await send(.initializationFailed(message))
                    }
                }
                .cancellable(id: CancelID.initialization)

            case .stopButtonTapped:
                guard case .recording = state.status else { return .none }
                state.status = .processing

                return .merge(
                    .cancel(id: CancelID.audioStream),
                    .cancel(id: CancelID.timer),
                    .run { send in
                        // 音声ストリーミングを停止
                        await streamingAudio.stopRecording()

                        do {
                            // 最終的な文字起こし結果を取得
                            let finalText = try await streamingTranscription.finalize()
                            await send(.finalizationCompleted(finalText))
                        } catch {
                            let message = (error as? StreamingTranscriptionError)?.errorDescription
                                ?? error.localizedDescription
                            await send(.finalizationFailed(message))
                        }
                    }
                )

            case .closeButtonTapped:
                // 録音中のみ確認ダイアログを表示
                if state.isRecording {
                    state.showCancelConfirmation = true
                    return .none
                }
                // それ以外は即座にキャンセル処理を実行
                return .send(.cancelButtonTapped)

            case .cancelConfirmationConfirmed:
                state.showCancelConfirmation = false
                return .send(.cancelButtonTapped)

            case .cancelConfirmationDismissed:
                state.showCancelConfirmation = false
                return .none

            case .cancelButtonTapped:
                let wasRecording = state.isRecording
                state.status = .idle
                state.confirmedText = ""
                state.pendingText = ""
                state.decodingText = ""
                state.duration = 0
                state.tokensPerSecond = 0

                return .merge(
                    .cancel(id: CancelID.audioStream),
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.initialization),
                    .run { send in
                        if wasRecording {
                            await streamingAudio.stopRecording()
                        }
                        await streamingTranscription.reset()
                        await send(.delegate(.streamingCancelled))
                    }
                )

            case .copyAndCloseButtonTapped:
                guard case let .completed(text) = state.status else { return .none }

                return .run { send in
                    _ = await outputClient.copyToClipboard(text)
                    await send(.delegate(.streamingCompleted(text)))
                    await send(.delegate(.closePopup))
                }

            case .saveToFileButtonTapped:
                guard case let .completed(text) = state.status else { return .none }

                return .run { [userDefaultsClient, outputClient] send in
                    do {
                        let appSettings = await userDefaultsClient.loadSettings()
                        var outputSettings = appSettings.output

                        // ブックマークを解決してアクセス権を取得
                        if let bookmarkData = outputSettings.outputBookmarkData,
                           let resolvedURL = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            outputSettings.outputDirectory = resolvedURL
                        }

                        let url = try await outputClient.saveToFile(text, outputSettings)
                        await send(.fileSaveCompleted(url))
                    } catch {
                        await send(.fileSaveFailed(error.localizedDescription))
                    }
                }

            // MARK: - 内部アクション

            case .initializationCompleted:
                state.status = .recording(duration: 0, tokensPerSecond: 0)

                // 音声ストリーミングとタイマーを開始
                return .merge(
                    // 音声ストリームを開始
                    .run { send in
                        do {
                            let stream = try await streamingAudio.startRecording()
                            for try await samples in stream {
                                await send(.audioChunkReceived(samples))
                            }
                        } catch {
                            logger.error("Audio stream error: \(error.localizedDescription)")
                        }
                    }
                    .cancellable(id: CancelID.audioStream),

                    // タイマーを開始
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                )

            case let .initializationFailed(message):
                state.status = .error(message)
                return .none

            case let .updateShowDecodingPreview(show):
                state.showDecodingPreview = show
                return .none

            case let .audioChunkReceived(samples):
                guard case .recording = state.status else { return .none }

                return .run { send in
                    do {
                        let progress = try await streamingTranscription.processChunk(samples)
                        await send(.progressUpdated(progress))
                    } catch {
                        logger.error("Chunk processing error: \(error.localizedDescription)")
                    }
                }

            case let .progressUpdated(progress):
                state.confirmedText = progress.confirmedText
                state.pendingText = progress.pendingText
                state.decodingText = progress.decodingText
                state.tokensPerSecond = progress.tokensPerSecond

                // statusのtokensPerSecondも更新
                if case let .recording(duration, _) = state.status {
                    state.status = .recording(duration: duration, tokensPerSecond: progress.tokensPerSecond)
                }
                return .none

            case .timerTick:
                if case let .recording(duration, tokensPerSecond) = state.status {
                    let newDuration = duration + 1
                    state.duration = newDuration
                    state.status = .recording(duration: newDuration, tokensPerSecond: tokensPerSecond)
                }
                return .none

            case let .finalizationCompleted(text):
                state.status = .completed(text: text)
                state.confirmedText = text
                state.pendingText = ""
                state.decodingText = ""

                return .run { [userDefaultsClient, outputClient] send in
                    await streamingTranscription.reset()

                    // ユーザー設定を読み込み
                    let appSettings = await userDefaultsClient.loadSettings()
                    let generalSettings = appSettings.general

                    // 完了通知を表示（設定が有効な場合）
                    if generalSettings.showNotificationOnComplete {
                        await outputClient.showNotification(
                            "WhisperPad",
                            "リアルタイム文字起こしが完了しました"
                        )
                    }

                    // 完了音を再生（設定が有効な場合）
                    if generalSettings.playSoundOnComplete {
                        await outputClient.playCompletionSound()
                    }

                    // 自動ファイル出力が有効な場合
                    if appSettings.output.isEnabled {
                        var outputSettings = appSettings.output

                        // ブックマークを解決してアクセス権を取得
                        if let bookmarkData = outputSettings.outputBookmarkData,
                           let resolvedURL = await userDefaultsClient.resolveBookmark(bookmarkData) {
                            outputSettings.outputDirectory = resolvedURL
                        }

                        do {
                            let url = try await outputClient.saveToFile(text, outputSettings)
                            await send(.fileSaveCompleted(url))
                        } catch {
                            await send(.fileSaveFailed(error.localizedDescription))
                        }
                    }
                }

            case let .finalizationFailed(message):
                state.status = .error(message)
                return .run { _ in await streamingTranscription.reset() }

            case let .fileSaveCompleted(url):
                return .run { _ in
                    await outputClient.showNotification(
                        "WhisperPad",
                        "ファイルを保存しました: \(url.lastPathComponent)"
                    )
                }

            case let .fileSaveFailed(message):
                // エラー通知（状態は変えない）
                return .run { _ in
                    await outputClient.showNotification(
                        "WhisperPad",
                        "保存に失敗しました: \(message)"
                    )
                }

            case .delegate:
                // 親Reducerで処理
                return .none
            }
        }
    }
}
