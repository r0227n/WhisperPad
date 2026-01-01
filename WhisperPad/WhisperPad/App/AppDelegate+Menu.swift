//
//  AppDelegate+Menu.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture

// MARK: - Menu Creation

extension AppDelegate {
    /// ドロップダウンメニューを作成
    /// - Returns: 設定済みの NSMenu
    func createMenu() -> NSMenu {
        let menu = NSMenu()

        addRecordingItems(to: menu)
        addStreamingItem(to: menu)
        menu.addItem(NSMenuItem.separator())
        addSettingsItem(to: menu)
        menu.addItem(NSMenuItem.separator())

        #if DEBUG
        addDebugMenu(to: menu)
        menu.addItem(NSMenuItem.separator())
        #endif

        addQuitItem(to: menu)

        return menu
    }

    private func addRecordingItems(to menu: NSMenu) {
        let hotKey = store.settings.settings.hotKey

        let recordingItem = NSMenuItem(
            title: "録音開始",
            action: #selector(startRecording),
            keyEquivalent: hotKey.recordingToggleHotKey.keyEquivalentCharacter
        )
        recordingItem.keyEquivalentModifierMask = hotKey.recordingToggleHotKey.keyEquivalentModifierMask
        recordingItem.tag = MenuItemTag.recording.rawValue
        recordingItem.target = self
        recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        menu.addItem(recordingItem)

        let pauseResumeItem = NSMenuItem(
            title: "一時停止",
            action: #selector(pauseRecording),
            keyEquivalent: hotKey.recordingPauseHotKey.keyEquivalentCharacter
        )
        pauseResumeItem.keyEquivalentModifierMask = hotKey.recordingPauseHotKey.keyEquivalentModifierMask
        pauseResumeItem.tag = MenuItemTag.pauseResume.rawValue
        pauseResumeItem.target = self
        pauseResumeItem.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: nil)
        pauseResumeItem.isHidden = true
        menu.addItem(pauseResumeItem)
    }

    private func addStreamingItem(to menu: NSMenu) {
        let streamingItem = NSMenuItem(
            title: "リアルタイム文字起こし",
            action: #selector(startStreaming),
            keyEquivalent: "r"
        )
        streamingItem.keyEquivalentModifierMask = NSEvent.ModifierFlags([.command, .shift])
        streamingItem.tag = MenuItemTag.streaming.rawValue
        streamingItem.target = self
        streamingItem.image = NSImage(systemSymbolName: "waveform.badge.mic", accessibilityDescription: nil)
        menu.addItem(streamingItem)
    }

    private func addSettingsItem(to menu: NSMenu) {
        let settingsItem = NSMenuItem(
            title: "設定...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        settingsItem.tag = MenuItemTag.settings.rawValue
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        menu.addItem(settingsItem)
    }

    private func addQuitItem(to menu: NSMenu) {
        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        quitItem.tag = MenuItemTag.quit.rawValue
        quitItem.target = self
        menu.addItem(quitItem)
    }
}

// MARK: - Menu Item Configuration

extension AppDelegate {
    func configureMenuItem(
        _ item: NSMenuItem,
        title: String,
        action: Selector?,
        symbol: String,
        isEnabled: Bool = true,
        keyEquivalent: String = "",
        keyEquivalentModifierMask: NSEvent.ModifierFlags = []
    ) {
        item.title = title
        item.action = action
        item.target = action != nil ? self : nil
        item.isEnabled = isEnabled
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        item.keyEquivalent = keyEquivalent
        item.keyEquivalentModifierMask = keyEquivalentModifierMask
    }
}
