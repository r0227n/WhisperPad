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
        // すべて解除
        await hotKeyClient.unregisterAll()

        let recordingMode = hotKeySettings.recordingMode

        // 録音ホットキー（Push-to-Talk対応）
        await hotKeyClient.registerRecordingWithCombo(
            hotKeySettings.recordingHotKey,
            { [weak self] in
                Task { @MainActor in
                    self?.handleRecordingKeyDown(mode: recordingMode)
                }
            },
            { [weak self] in
                Task { @MainActor in
                    self?.handleRecordingKeyUp(mode: recordingMode)
                }
            }
        )

        // ペーストホットキー
        await hotKeyClient.registerPasteWithCombo(
            hotKeySettings.pasteHotKey,
            { [weak self] in
                Task { @MainActor in
                    self?.pasteLastTranscription()
                }
            }
        )

        // 設定を開くホットキー
        await hotKeyClient.registerOpenSettingsWithCombo(
            hotKeySettings.openSettingsHotKey,
            {
                Task { @MainActor in
                    NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
                }
            }
        )

        // キャンセルホットキー
        await hotKeyClient.registerCancelWithCombo(
            hotKeySettings.cancelHotKey,
            { [weak self] in
                Task { @MainActor in
                    self?.cancelRecording()
                }
            }
        )

        logger.info("Hotkeys registered from settings")
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
}
