//
//  AppDelegate+PopupHotKey.swift
//  WhisperPad
//

import ComposableArchitecture
import Dependencies
import Foundation
import os.log

// MARK: - Popup HotKey Management

extension AppDelegate {
    /// ポップアップ用ホットキーを登録
    ///
    /// ポップアップが表示されたときに呼び出され、
    /// コピーして閉じる、ファイル保存、閉じるのホットキーを登録します。
    /// グローバルキャンセルホットキーは一時的に解除されます。
    func registerPopupHotKeys() {
        Task {
            @Dependency(\.userDefaultsClient) var userDefaultsClient
            let settings = await userDefaultsClient.loadSettings()

            // グローバルキャンセルホットキー（Esc）を一時解除
            await hotKeyClient.unregisterCancel()
            logger.info("Global cancel hotkey unregistered for popup")

            // ポップアップ用ホットキーを登録
            await hotKeyClient.registerPopupCopyAndClose(
                settings.hotKey.popupCopyAndCloseHotKey,
                { [weak self] in Task { @MainActor in self?.handlePopupCopyAndClose() } }
            )

            await hotKeyClient.registerPopupSaveToFile(
                settings.hotKey.popupSaveToFileHotKey,
                { [weak self] in Task { @MainActor in self?.handlePopupSaveToFile() } }
            )

            await hotKeyClient.registerPopupClose(
                settings.hotKey.popupCloseHotKey,
                { [weak self] in Task { @MainActor in self?.handlePopupClose() } }
            )

            logger.info("Popup hotkeys registered")
        }
    }

    /// ポップアップ用ホットキーを解除
    ///
    /// ポップアップが閉じられたときに呼び出され、
    /// ポップアップ用ホットキーを解除し、グローバルキャンセルホットキーを再登録します。
    func unregisterPopupHotKeys() {
        Task {
            await hotKeyClient.unregisterPopupHotKeys()
            logger.info("Popup hotkeys unregistered")

            // グローバルキャンセルホットキーを再登録
            @Dependency(\.userDefaultsClient) var userDefaultsClient
            let settings = await userDefaultsClient.loadSettings()
            await hotKeyClient.registerCancelWithCombo(
                settings.hotKey.cancelHotKey,
                { [weak self] in Task { @MainActor in self?.cancelRecording() } }
            )
            logger.info("Global cancel hotkey re-registered")
        }
    }

    // MARK: - Popup Hotkey Handlers

    /// ポップアップ: コピーして閉じるハンドラー
    func handlePopupCopyAndClose() {
        // 完了状態でのみ有効
        guard store.streamingTranscription.isCompleted else {
            logger.info("Popup copy & close ignored: not in completed state")
            return
        }
        logger.info("Popup copy & close hotkey pressed")
        store.send(.streamingTranscription(.copyAndCloseButtonTapped))
    }

    /// ポップアップ: ファイル保存ハンドラー
    func handlePopupSaveToFile() {
        // 完了状態でのみ有効
        guard store.streamingTranscription.isCompleted else {
            logger.info("Popup save to file ignored: not in completed state")
            return
        }
        logger.info("Popup save to file hotkey pressed")
        store.send(.streamingTranscription(.saveToFileButtonTapped))
    }

    /// ポップアップ: 閉じるハンドラー
    func handlePopupClose() {
        // ポップアップが表示されている場合のみ
        guard getStreamingPopupWindow() != nil else {
            logger.info("Popup close ignored: popup not visible")
            return
        }
        logger.info("Popup close hotkey pressed")
        store.send(.streamingTranscription(.closeButtonTapped))
    }
}
