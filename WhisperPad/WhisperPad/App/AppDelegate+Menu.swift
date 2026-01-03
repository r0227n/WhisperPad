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
        addModelSubmenu(to: menu)
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

    private func addModelSubmenu(to menu: NSMenu) {
        let modelSubmenu = NSMenu(title: localizedAppString(forKey: "menu.model.title"))

        // ヘッダー（現在のモデルを表示、無効化）
        let currentModel = store.settings.settings.transcription.modelName
        let displayName = WhisperModel.from(id: currentModel).displayName
        let currentModelItem = NSMenuItem(
            title: String(
                format: localizedAppString(forKey: "menu.model.current"),
                displayName
            ),
            action: nil,
            keyEquivalent: ""
        )
        currentModelItem.isEnabled = false
        modelSubmenu.addItem(currentModelItem)

        modelSubmenu.addItem(NSMenuItem.separator())

        // ダウンロード済みモデルリスト（動的に更新される）

        modelSubmenu.addItem(NSMenuItem.separator())

        // "More models..."項目
        let moreModelsItem = NSMenuItem(
            title: localizedAppString(forKey: "menu.model.more"),
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        moreModelsItem.target = self
        moreModelsItem.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        modelSubmenu.addItem(moreModelsItem)

        let modelItem = NSMenuItem(
            title: localizedAppString(forKey: "menu.model.title"),
            action: nil,
            keyEquivalent: ""
        )
        modelItem.tag = MenuItemTag.modelSubmenu.rawValue
        modelItem.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)
        modelItem.submenu = modelSubmenu
        menu.addItem(modelItem)
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

        // WhisperKit初期化中は最優先で処理
        if store.whisperKitState == .initializing {
            configureMenuForWhisperKitInitializing(recordingItem, pauseResumeItem, cancelItem)
            updateModelSubmenu()
            return
        }

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

        // モデルサブメニューを更新
        updateModelSubmenu()
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

    private func configureMenuForWhisperKitInitializing(
        _ recordingItem: NSMenuItem,
        _ pauseResumeItem: NSMenuItem,
        _ cancelItem: NSMenuItem
    ) {
        configureMenuItem(
            recordingItem,
            title: localizedAppString(forKey: "menu.model.loading"),
            action: nil,
            symbol: "gear",
            isEnabled: false
        )
        pauseResumeItem.isHidden = true
        cancelItem.isHidden = true
    }

    private func updateModelSubmenu() {
        guard let menu = statusMenu,
              let modelMenuItem = menu.item(withTag: MenuItemTag.modelSubmenu.rawValue),
              let modelSubmenu = modelMenuItem.submenu
        else { return }

        let currentModel = store.settings.settings.transcription.modelName
        let downloadedModels = store.downloadedModels

        // ヘッダー項目を更新（最初の項目）
        if let currentModelHeaderItem = modelSubmenu.items.first {
            let displayName = WhisperModel.from(id: currentModel).displayName
            currentModelHeaderItem.title = String(
                format: localizedAppString(forKey: "menu.model.current"),
                displayName
            )
        }

        // 既存のモデル項目を削除（セパレーター間）
        let firstSeparatorIndex = modelSubmenu.items.firstIndex { $0.isSeparatorItem } ?? 1
        let secondSeparatorIndex = modelSubmenu.items.dropFirst(firstSeparatorIndex + 1)
            .firstIndex { $0.isSeparatorItem }
            .map { firstSeparatorIndex + 1 + $0 } ?? modelSubmenu.items.count - 2

        for index in (firstSeparatorIndex + 1 ..< secondSeparatorIndex).reversed() {
            modelSubmenu.removeItem(at: index)
        }

        let insertionIndex = firstSeparatorIndex + 1

        if downloadedModels.isEmpty {
            // モデルなし
            let emptyItem = NSMenuItem(
                title: localizedAppString(forKey: "menu.model.empty"),
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            modelSubmenu.insertItem(emptyItem, at: insertionIndex)
        } else {
            // ダウンロード済みモデルを追加
            for (offset, model) in downloadedModels.enumerated() {
                let modelItem = NSMenuItem(
                    title: model.displayName,
                    action: #selector(selectModelFromMenu(_:)),
                    keyEquivalent: ""
                )
                modelItem.target = self
                modelItem.representedObject = model.id

                // 現在のモデルにチェックマーク
                if model.id == currentModel {
                    modelItem.state = .on
                }

                // idle状態かつWhisperKit未初期化の場合のみ有効
                let canSwitch = (store.appStatus == .idle ||
                    store.appStatus == .completed ||
                    store.appStatus == .error) &&
                    store.whisperKitState != .initializing
                modelItem.isEnabled = canSwitch

                modelSubmenu.insertItem(modelItem, at: insertionIndex + offset)
            }
        }
    }
}
