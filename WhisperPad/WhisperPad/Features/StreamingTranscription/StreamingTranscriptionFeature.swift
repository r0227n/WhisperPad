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
// swiftlint:disable:next type_body_length
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

        /// アクティブな操作中かどうか（録音中または処理中）
        var isActiveOperation: Bool {
            if case .recording = status { return true }
            if case .processing = status { return true }
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

        /// ポップアップ用ホットキー表示文字列
        var popupSaveToFileShortcut: String = HotKeySettings.KeyComboSettings.popupSaveToFileDefault.displayString
        var popupCopyAndCloseShortcut: String = HotKeySettings.KeyComboSettings.popupCopyAndCloseDefault.displayString
        var popupCloseShortcut: String = HotKeySettings.KeyComboSettings.popupCloseDefault.displayString

        /// WhisperKit初期化中フラグ
        var whisperKitInitializing: Bool = false
    }

    // MARK: - Action

    enum Action: Sendable, BindableAction {
        // ライフサイクル
        /// ビューが表示された
        case onAppear

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
        /// Service初期化開始
        case initializeStreamingService
        /// Service初期化完了
        case serviceInitializationCompleted
        /// Service初期化失敗
        case serviceInitializationFailed(String)
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
        /// ポップアップ用ホットキー設定を読み込み完了
        case popupHotKeysLoaded(saveToFile: String, copyAndClose: String, close: String)

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
        Reduce<State, Action> { (state: inout State, action: Action) -> Effect<Action> in
            switch action {
            case .binding:
                return .none
            // MARK: - ライフサイクル
            case .onAppear:
                return .run { [userDefaultsClient] send in
                    let settings = await userDefaultsClient.loadSettings()
                    let hotKeySettings = settings.hotKey
                    await send(.popupHotKeysLoaded(
                        saveToFile: hotKeySettings.popupSaveToFileHotKey.displayString,
                        copyAndClose: hotKeySettings.popupCopyAndCloseHotKey.displayString,
                        close: hotKeySettings.popupCloseHotKey.displayString
                    ))
                }
            // MARK: - ユーザー操作
            case .startButtonTapped:
                guard state.status == .idle else { return .none }
                state.status = .initializing
                state.confirmedText = ""
                state.pendingText = ""
                state.decodingText = ""
                state.duration = 0
                state.tokensPerSecond = 0

                // RecordingFeatureと同様に、まずWhisperKit準備状態をチェック
                return .send(.checkWhisperKitReady)

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
                // 録音中または処理中は確認ダイアログを表示
                if state.isActiveOperation {
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
            case .checkWhisperKitReady:
                return .run { send in
                    let isReady = await whisperKitClient.isReady()
                    if isReady {
                        await send(.whisperKitReady)
                    } else {
                        await send(.initializeWhisperKit)
                    }
                }

            case .whisperKitReady:
                return .send(.initializeStreamingService)

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
                return .send(.initializeStreamingService)

            case let .whisperKitInitFailed(error):
                state.whisperKitInitializing = false
                let message = (error as? WhisperKitManagerError)?.errorDescription
                    ?? error.localizedDescription
                state.status = .error(message)
                return .none

            case .initializeStreamingService:
                return .run { [streamingTranscription, userDefaultsClient] send in
                    do {
                        // UserDefaultsから設定を読み込み
                        let settings = await userDefaultsClient.loadSettings()
                        let confirmationCount = settings.streaming.confirmationCount
                        let language = settings.streaming.language
                        try await streamingTranscription.initialize(nil, confirmationCount, language)
                        await send(.serviceInitializationCompleted)
                    } catch {
                        let message = (error as? StreamingTranscriptionError)?.errorDescription
                            ?? error.localizedDescription
                        await send(.serviceInitializationFailed(message))
                    }
                }
                .cancellable(id: CancelID.initialization)

            case .serviceInitializationCompleted:
                state.status = .recording(duration: 0, tokensPerSecond: 0)
                return .merge(
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
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                )

            case let .serviceInitializationFailed(message):
                state.status = .error(message)
                return .none

            case let .audioChunkReceived(samples):
                guard case .recording = state.status else { return .none }

                return .run { send in
                    do {
                        let progress = try await streamingTranscription.processChunk(samples)
                        await send(.progressUpdated(progress))
                    } catch let error as StreamingTranscriptionError {
                        // 型安全なエラー処理
                        switch error {
                        case .bufferOverflow:
                            // バッファオーバーフロー時は自動停止
                            logger.error("Buffer overflow occurred, stopping recording")
                            await send(.stopButtonTapped)
                        default:
                            logger.error("Streaming error: \(error.localizedDescription)")
                        }
                    } catch {
                        logger.error("Chunk processing error: \(error.localizedDescription)")
                    }
                }

            case let .progressUpdated(progress):
                state.confirmedText = progress.confirmedText
                state.pendingText = progress.pendingText
                state.decodingText = progress.decodingText
                state.tokensPerSecond = progress.tokensPerSecond
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

            case let .popupHotKeysLoaded(saveToFile, copyAndClose, close):
                state.popupSaveToFileShortcut = saveToFile
                state.popupCopyAndCloseShortcut = copyAndClose
                state.popupCloseShortcut = close
                return .none

            case .delegate:
                // 親Reducerで処理
                return .none
            }
        }
    }
}
