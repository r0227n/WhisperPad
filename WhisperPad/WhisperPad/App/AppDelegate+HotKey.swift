//
//  AppDelegate+HotKey.swift
//  WhisperPad
//

import ComposableArchitecture
import Dependencies
import Foundation
import os.log

// MARK: - HotKey Management

extension AppDelegate {
    /// ホットキー設定変更の通知を監視
    func setupHotKeyObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotKeySettingsChanged),
            name: .hotKeySettingsChanged,
            object: nil
        )
    }

    @objc func handleHotKeySettingsChanged(_ notification: Notification) {
        guard let hotKeySettings = notification.object as? HotKeySettings else {
            logger.warning("Invalid hotkey settings in notification")
            return
        }
        logger.info("Hot key settings changed, re-registering hotkeys")
        Task {
            await registerHotKeysFromSettings(hotKeySettings)
        }
    }

    /// グローバルホットキーを設定（保存された設定を使用）
    func setupHotKeys() {
        Task {
            // アクセシビリティ権限をチェック
            let hasPermission = await hotKeyClient.checkAccessibilityPermission()

            if !hasPermission {
                logger.warning("Accessibility permission not granted, requesting...")
                await hotKeyClient.requestAccessibilityPermission()
            }

            // 保存された設定を読み込み
            @Dependency(\.userDefaultsClient) var userDefaultsClient
            let settings = await userDefaultsClient.loadSettings()

            await registerHotKeysFromSettings(settings.hotKey)
        }
    }

    /// 設定からホットキーを登録
    func registerHotKeysFromSettings(_ hotKeySettings: HotKeySettings) async {
        await hotKeyClient.unregisterAll()

        await registerRecordingHotKey(hotKeySettings)
        await registerPasteHotKey(hotKeySettings)
        await registerOpenSettingsHotKey(hotKeySettings)
        await registerCancelHotKey(hotKeySettings)
        await registerStreamingHotKey(hotKeySettings)
        await registerRecordingToggleHotKey(hotKeySettings)
        await registerRecordingPauseHotKey(hotKeySettings)

        logger.info("Hotkeys registered from settings")
    }

    private func registerRecordingHotKey(_ settings: HotKeySettings) async {
        let mode = settings.recordingMode
        await hotKeyClient.registerRecordingWithCombo(
            settings.recordingHotKey,
            { [weak self] in Task { @MainActor in self?.handleRecordingKeyDown(mode: mode) } },
            { [weak self] in Task { @MainActor in self?.handleRecordingKeyUp(mode: mode) } }
        )
    }

    private func registerPasteHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerPasteWithCombo(
            settings.pasteHotKey,
            { [weak self] in Task { @MainActor in self?.pasteLastTranscription() } }
        )
    }

    private func registerOpenSettingsHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerOpenSettingsWithCombo(
            settings.openSettingsHotKey,
            { Task { @MainActor in NotificationCenter.default.post(name: .openSettingsRequest, object: nil) } }
        )
    }

    private func registerCancelHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerCancelWithCombo(
            settings.cancelHotKey,
            { [weak self] in Task { @MainActor in self?.cancelRecording() } }
        )
    }

    private func registerStreamingHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerStreamingWithCombo(
            settings.streamingHotKey,
            { [weak self] in Task { @MainActor in self?.handleStreamingKeyDown() } },
            { [weak self] in Task { @MainActor in self?.handleStreamingKeyUp() } }
        )
    }

    private func registerRecordingToggleHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerRecordingToggleWithCombo(
            settings.recordingToggleHotKey,
            { [weak self] in Task { @MainActor in self?.handleRecordingToggleKeyDown() } }
        )
    }

    private func registerRecordingPauseHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerRecordingPauseWithCombo(
            settings.recordingPauseHotKey,
            { [weak self] in Task { @MainActor in self?.handleRecordingPauseKeyDown() } }
        )
    }

    /// 録音キーダウンハンドラー（recordingMode対応）
    func handleRecordingKeyDown(mode: HotKeySettings.RecordingMode) {
        switch mode {
        case .toggle:
            toggleRecording()
        case .pushToTalk:
            // 録音中でなければ開始
            switch store.appStatus {
            case .idle, .completed, .error, .streamingCompleted:
                logger.info("Push-to-Talk: Key down, starting recording")
                store.send(.startRecording)
            default:
                break
            }
        }
    }

    /// 録音キーアップハンドラー（Push-to-Talk用）
    func handleRecordingKeyUp(mode: HotKeySettings.RecordingMode) {
        guard mode == .pushToTalk else { return }
        // 録音中または一時停止中なら終了
        if store.appStatus == .recording || store.appStatus == .paused {
            logger.info("Push-to-Talk: Key up, ending recording")
            store.send(.endRecording)
        }
    }

    /// ストリーミングキーダウンハンドラー
    func handleStreamingKeyDown() {
        logger.info("Streaming hotkey pressed: ⌘⇧R")
        toggleStreaming()
    }

    /// ストリーミングキーアップハンドラー（Push-to-Talk）
    func handleStreamingKeyUp() {
        // Push-to-Talk: ストリーミング中ならキーを離したときに停止
        if store.appStatus == .streamingTranscribing {
            logger.info("Streaming Push-to-Talk: Key up, stopping streaming")
            store.send(.streamingTranscription(.stopButtonTapped))
        }
    }

    /// 録音開始/終了トグルキーダウンハンドラー
    func handleRecordingToggleKeyDown() {
        logger.info("Recording toggle hotkey pressed: ⌥⇧S")
        switch store.appStatus {
        case .idle, .completed, .error, .streamingCompleted:
            store.send(.startRecording)
        case .recording, .paused:
            store.send(.endRecording)
        default:
            logger.info("Recording toggle ignored: transcribing")
        }
    }

    /// 録音一時停止キーダウンハンドラー
    func handleRecordingPauseKeyDown() {
        logger.info("Recording pause hotkey pressed: ⌥⇧P")
        switch store.appStatus {
        case .recording:
            store.send(.pauseRecording)
        case .paused:
            store.send(.resumeRecording)
        default:
            logger.info("Recording pause ignored: not recording")
        }
    }
}
