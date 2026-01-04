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
        addCancelItem(to: menu)
        menu.addItem(NSMenuItem.separator())
        addModelSelectionItem(to: menu)
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
            title: localizedAppString(forKey: "menu.recording.start"),
            action: #selector(startRecording),
            keyEquivalent: hotKey.recordingHotKey.keyEquivalentCharacter
        )
        recordingItem.keyEquivalentModifierMask = hotKey.recordingHotKey.keyEquivalentModifierMask
        recordingItem.tag = MenuItemTag.recording.rawValue
        recordingItem.target = self
        recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        menu.addItem(recordingItem)

        let pauseResumeItem = NSMenuItem(
            title: localizedAppString(forKey: "menu.recording.pause"),
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

    private func addCancelItem(to menu: NSMenu) {
        let hotKey = store.settings.settings.hotKey

        let cancelItem = NSMenuItem(
            title: localizedAppString(forKey: "menu.cancel"),
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
            title: localizedAppString(forKey: "menu.settings"),
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
            title: localizedAppString(forKey: "menu.quit"),
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        quitItem.tag = MenuItemTag.quit.rawValue
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addModelSelectionItem(to menu: NSMenu) {
        let modelItem = NSMenuItem(
            title: localizedAppString(forKey: "menu.model.selection") + ": " +
                localizedAppString(forKey: "menu.model.unloaded"),
            action: nil,
            keyEquivalent: ""
        )
        modelItem.tag = MenuItemTag.modelSelection.rawValue
        modelItem.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)

        // サブメニューを作成
        let submenu = NSMenu()
        modelItem.submenu = submenu

        menu.addItem(modelItem)

        // 初期化時にモデル一覧を取得
        store.send(.fetchAvailableModels)
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
              let cancelItem = menu.item(withTag: MenuItemTag.cancel.rawValue)
        else { return }

        let hotKey = store.settings.settings.hotKey

        switch store.appStatus {
        case .idle, .completed, .error:
            configureMenuForIdleState(recordingItem, pauseResumeItem, cancelItem, hotKey)
        case .recording:
            configureMenuForRecordingState(recordingItem, pauseResumeItem, cancelItem, hotKey)
        case .paused:
            configureMenuForPausedState(recordingItem, pauseResumeItem, cancelItem, hotKey)
        case .transcribing:
            configureMenuForTranscribingState(recordingItem, pauseResumeItem, cancelItem)
        }
    }

    private func configureMenuForIdleState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        configureMenuItem(
            recordingItem,
            title: localizedAppString(forKey: "menu.recording.start"),
            action: #selector(startRecording),
            symbol: "mic.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = true
        cancelItem.isHidden = true
    }

    private func configureMenuForRecordingState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        let pauseKey = hotKey.recordingPauseHotKey
        let cancelKey = hotKey.cancelHotKey
        configureMenuItem(
            recordingItem,
            title: localizedAppString(forKey: "menu.recording.stop"),
            action: #selector(endRecording),
            symbol: "stop.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            pauseResumeItem,
            title: localizedAppString(forKey: "menu.recording.pause"),
            action: #selector(pauseRecording),
            symbol: "pause.fill",
            keyEquivalent: pauseKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: pauseKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            cancelItem,
            title: localizedAppString(forKey: "menu.cancel"),
            action: #selector(cancelMenuItemTapped),
            symbol: "xmark.circle.fill",
            keyEquivalent: cancelKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: cancelKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = false
        cancelItem.isHidden = false
    }

    private func configureMenuForPausedState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ cancelItem: NSMenuItem,
        _ hotKey: HotKeySettings
    ) {
        let toggleKey = hotKey.recordingHotKey
        let pauseKey = hotKey.recordingPauseHotKey
        let cancelKey = hotKey.cancelHotKey
        configureMenuItem(
            recordingItem,
            title: localizedAppString(forKey: "menu.recording.stop"),
            action: #selector(endRecording),
            symbol: "stop.fill",
            keyEquivalent: toggleKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: toggleKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            pauseResumeItem,
            title: localizedAppString(forKey: "menu.recording.resume"),
            action: #selector(resumeRecording),
            symbol: "play.fill",
            keyEquivalent: pauseKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: pauseKey.keyEquivalentModifierMask
        )
        configureMenuItem(
            cancelItem,
            title: localizedAppString(forKey: "menu.cancel"),
            action: #selector(cancelMenuItemTapped),
            symbol: "xmark.circle.fill",
            keyEquivalent: cancelKey.keyEquivalentCharacter,
            keyEquivalentModifierMask: cancelKey.keyEquivalentModifierMask
        )
        pauseResumeItem.isHidden = false
        cancelItem.isHidden = false
    }

    private func configureMenuForTranscribingState(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ cancelItem: NSMenuItem
    ) {
        configureMenuItem(
            recordingItem,
            title: localizedAppString(forKey: "menu.transcribing"),
            action: nil,
            symbol: "gear",
            isEnabled: false
        )
        pauseResumeItem.isHidden = true
        cancelItem.isHidden = true
    }

    /// モデルメニューの状態を更新
    func updateModelMenuForCurrentState() {
        guard let menu = statusMenu,
              let modelItem = menu.item(withTag: MenuItemTag.modelSelection.rawValue),
              let submenu = modelItem.submenu
        else { return }

        // メインメニュー項目のタイトルを更新
        let modelPrefix = localizedAppString(forKey: "menu.model.selection")
        let modelStatus: String

        // Check if app is in idle state (required to enable model selection)
        let isAppIdle: Bool = {
            if case .idle = store.appStatus {
                return true
            }
            return false
        }()

        switch store.modelState {
        case .unloaded:
            modelStatus = localizedAppString(forKey: "menu.model.unloaded")
            modelItem.isEnabled = isAppIdle

        case let .downloading(progress):
            let progressPercent = Int(progress * 100)
            modelStatus = localizedAppString(forKey: "menu.model.downloading")
                .replacingOccurrences(of: "{progress}", with: "\(progressPercent)")
            modelItem.isEnabled = false

        case .loading:
            modelStatus = localizedAppString(forKey: "menu.model.loading")
            modelItem.isEnabled = false

        case .loaded:
            if let currentModel = store.currentModelName {
                modelStatus = currentModel
            } else {
                modelStatus = localizedAppString(forKey: "menu.model.unloaded")
            }
            modelItem.isEnabled = isAppIdle

        case .error:
            modelStatus = localizedAppString(forKey: "menu.model.error")
            modelItem.isEnabled = isAppIdle
        }

        modelItem.title = "\(modelPrefix): \(modelStatus)"

        // サブメニューを更新
        updateModelSubmenu(submenu)
    }

    /// モデルサブメニューを更新
    private func updateModelSubmenu(_ submenu: NSMenu) {
        submenu.removeAllItems()

        // 利用可能なモデルがない場合
        guard !store.availableModels.isEmpty else {
            let noModelsItem = NSMenuItem(
                title: localizedAppString(forKey: "menu.model.no_models"),
                action: nil,
                keyEquivalent: ""
            )
            noModelsItem.isEnabled = false
            submenu.addItem(noModelsItem)
            return
        }

        // 各モデルをサブメニューに追加
        for modelName in store.availableModels {
            let modelMenuItem = NSMenuItem(
                title: modelName,
                action: #selector(modelMenuItemTapped(_:)),
                keyEquivalent: ""
            )
            modelMenuItem.target = self
            modelMenuItem.representedObject = modelName

            // 現在のモデルにチェックマークを付ける
            if modelName == store.currentModelName {
                modelMenuItem.state = .on
            }

            submenu.addItem(modelMenuItem)
        }
    }
}
