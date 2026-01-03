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

        // 既存のタスクをキャンセル（重複実行を防ぐ）
        getHotKeyRegistrationTask()?.cancel()

        // 新しいタスクを開始
        setHotKeyRegistrationTask(Task {
            // 少し待機してから実行（連続変更をまとめる）
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            await registerHotKeysFromSettings(hotKeySettings)
        })
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
        // unregisterAll() は呼ばない（個別に置き換える方が安全）

        // 各ホットキーを個別に再登録（古いものは自動的に置き換わる）
        await registerRecordingHotKey(hotKeySettings)
        await registerCancelHotKey(hotKeySettings)
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

    private func registerRecordingPauseHotKey(_ settings: HotKeySettings) async {
        await hotKeyClient.registerRecordingPauseWithCombo(
            settings.recordingPauseHotKey,
            { [weak self] in Task { @MainActor in self?.handleRecordingPauseKeyDown() } }
        )
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
