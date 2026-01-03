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
        addCancelItem(to: menu)
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
            title: String(localized: "menu.recording.start", comment: "Start Recording"),
            action: #selector(startRecording),
            keyEquivalent: hotKey.recordingHotKey.keyEquivalentCharacter
        )
        recordingItem.keyEquivalentModifierMask = hotKey.recordingHotKey.keyEquivalentModifierMask
        recordingItem.tag = MenuItemTag.recording.rawValue
        recordingItem.target = self
        recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        menu.addItem(recordingItem)

        let pauseResumeItem = NSMenuItem(
            title: String(localized: "menu.recording.pause", comment: "Pause"),
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
            title: String(localized: "menu.streaming.start", comment: "Real-time Transcription"),
            action: #selector(startStreaming),
            keyEquivalent: "r"
        )
        streamingItem.keyEquivalentModifierMask = NSEvent.ModifierFlags([.command, .shift])
        streamingItem.tag = MenuItemTag.streaming.rawValue
        streamingItem.target = self
        streamingItem.image = NSImage(systemSymbolName: "waveform.badge.mic", accessibilityDescription: nil)
        menu.addItem(streamingItem)
    }

    private func addCancelItem(to menu: NSMenu) {
        let hotKey = store.settings.settings.hotKey

        let cancelItem = NSMenuItem(
            title: String(localized: "menu.cancel", comment: "Cancel"),
            action: #selector(cancelMenuItemTapped),
            keyEquivalent: hotKey.cancelHotKey.keyEquivalentCharacter
        )
        cancelItem.keyEquivalentModifierMask = hotKey.cancelHotKey.keyEquivalentModifierMask
        cancelItem.tag = MenuItemTag.cancel.rawValue
        cancelItem.target = self
        cancelItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        cancelItem.isHidden = true
        menu.addItem(cancelItem)
    }

    private func addSettingsItem(to menu: NSMenu) {
        let settingsItem = NSMenuItem(
            title: String(localized: "menu.settings", comment: "Settings..."),
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
            title: String(localized: "menu.quit", comment: "Quit"),
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

// MARK: - Menu State Updates

extension AppDelegate {
    /// 現在の状態に応じてメニューを更新
    func updateMenuForCurrentState() {
        guard let menu = statusMenu,
              let recordingItem = menu.item(withTag: MenuItemTag.recording.rawValue),
              let pauseResumeItem = menu.item(withTag: MenuItemTag.pauseResume.rawValue),
              let streamingItem = menu.item(withTag: MenuItemTag.streaming.rawValue),
              let cancelItem = menu.item(withTag: MenuItemTag.cancel.rawValue)
        else { return }

        let hotKey = store.settings.settings.hotKey

        switch store.appStatus {
        case .idle, .completed, .error, .streamingCompleted:
            configureMenuForIdleState(recordingItem, pauseResumeItem, streamingItem, cancelItem, hotKey)
        case .recording:
            configureMenuForRecordingState(recordingItem, pauseResumeItem, streamingItem, cancelItem, hotKey)
        case .paused:
            configureMenuForPausedState(recordingItem, pauseResumeItem, streamingItem, cancelItem, hotKey)
        case .transcribing:
            configureMenuForTranscribingState(recordingItem, pauseResumeItem, streamingItem, cancelItem)
        case .streamingTranscribing:
            configureMenuForStreamingState(recordingItem, pauseResumeItem, streamingItem, cancelItem, hotKey)
        }
    }

    private func configureMenuForIdleState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ streamingItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        configureMenuItem(
            recordingItem,
            title: String(localized: "menu.recording.start", comment: "Start Recording"),
            action: #selector(startRecording),
            symbol: "mic.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        streamingItem.isEnabled = true
        pauseResumeItem.isHidden = true
        cancelItem.isHidden = true
    }

    private func configureMenuForRecordingState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ streamingItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        let pauseKey = hotKey.recordingPauseHotKey
        let cancelKey = hotKey.cancelHotKey
        configureMenuItem(
            recordingItem,
            title: String(localized: "menu.recording.stop", comment: "Stop Recording"),
            action: #selector(endRecording),
            symbol: "stop.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            pauseResumeItem,
            title: String(localized: "menu.recording.pause", comment: "Pause"),
            action: #selector(pauseRecording),
            symbol: "pause.fill",
            keyEquivalent: pauseKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: pauseKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            cancelItem,
            title: String(localized: "menu.cancel", comment: "Cancel"),
            action: #selector(cancelMenuItemTapped),
            symbol: "xmark.circle.fill",
            keyEquivalent: cancelKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: cancelKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = false
        streamingItem.isEnabled = false
        cancelItem.isHidden = false
    }

    private func configureMenuForPausedState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ streamingItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        let pauseKey = hotKey.recordingPauseHotKey
        let cancelKey = hotKey.cancelHotKey
        configureMenuItem(
            recordingItem,
            title: String(localized: "menu.recording.stop", comment: "Stop Recording"),
            action: #selector(endRecording),
            symbol: "stop.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            pauseResumeItem,
            title: String(localized: "menu.recording.resume", comment: "Resume Recording"),
            action: #selector(resumeRecording),
            symbol: "play.fill",
            keyEquivalent: pauseKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: pauseKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            cancelItem,
            title: String(localized: "menu.cancel", comment: "Cancel"),
            action: #selector(cancelMenuItemTapped),
            symbol: "xmark.circle.fill",
            keyEquivalent: cancelKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: cancelKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = false
        streamingItem.isEnabled = false
        cancelItem.isHidden = false
    }

    private func configureMenuForTranscribingState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ streamingItem: NSMenuItem,
        _ cancelItem: NSMenuItem
    ) {
        configureMenuItem(
            recordingItem,
            title: String(localized: "menu.transcribing", comment: "Transcribing..."),
            action: nil,
            symbol: "gear",
            isEnabled: false
        )
        pauseResumeItem.isHidden = true
        streamingItem.isEnabled = false
        cancelItem.isHidden = true
    }

    private func configureMenuForStreamingState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ streamingItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let cancelKey = hotKey.cancelHotKey
        configureMenuItem(
            recordingItem,
            title: String(localized: "menu.streaming.in_progress", comment: "Streaming..."),
            action: nil,
            symbol: "waveform.badge.mic",
            isEnabled: false
        )
        configureMenuItem(
            cancelItem,
            title: String(localized: "menu.cancel", comment: "Cancel"),
            action: #selector(cancelMenuItemTapped),
            symbol: "xmark.circle.fill",
            keyEquivalent: cancelKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: cancelKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = true
        streamingItem.isEnabled = false
        cancelItem.isHidden = false
    }
}
