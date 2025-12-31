//
//  AppDelegate+StreamingPopup.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation
import os.log

// MARK: - Streaming Popup Management

extension AppDelegate {
    /// ストリーミングポップアップ関連の通知を監視
    func setupStreamingPopupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloseStreamingPopup),
            name: .closeStreamingPopup,
            object: nil
        )
    }

    @objc func handleCloseStreamingPopup(_ notification: Notification) {
        closeStreamingPopup()
    }

    /// ストリーミングポップアップを表示
    func showStreamingPopup() {
        closeStreamingPopup()

        let popupStore = store.scope(
            state: \.streamingTranscription,
            action: \.streamingTranscription
        )
        let popup = StreamingPopupWindow(store: popupStore)

        if let statusItem = getStatusItem() {
            popup.showBelowMenuBarIcon(relativeTo: statusItem)
        }

        setStreamingPopupWindow(popup)
        logger.info("Streaming popup window shown")
    }

    /// ストリーミングポップアップを閉じる
    func closeStreamingPopup() {
        getStreamingPopupWindow()?.close()
        setStreamingPopupWindow(nil)
        logger.info("Streaming popup window closed")
    }
}
