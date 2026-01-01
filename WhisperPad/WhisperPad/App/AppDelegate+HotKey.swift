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
        await registerCancelHotKey(hotKeySettings)
        await registerStreamingHotKey(hotKeySettings)
        await registerRecordingToggleHotKey(hotKeySettings)
        await registerRecordingPauseHotKey(hotKeySettings)

        logger.info("Hotkeys registered from settings")
    }

    private func registerRecordingHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerRecordingWithCombo(
            settings.recordingHotKey,
            { [weak self] in Task { @MainActor in self?.toggleRecording() } }
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
