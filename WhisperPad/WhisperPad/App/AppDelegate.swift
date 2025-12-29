//
//  AppDelegate.swift
//  WhisperPad
//

import AppKit
import os.log

/// メニューバーアプリケーションを管理する AppDelegate
///
/// `NSStatusItem` を使用してメニューバーにアイコンを表示し、
/// ドロップダウンメニューを提供します。
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// メニューバーに表示されるステータスアイテム
    private var statusItem: NSStatusItem?

    /// ステータスアイテムのメニュー
    private var statusMenu: NSMenu?

    /// ロガー
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
        category: "AppDelegate"
    )

    // MARK: - Menu Item Tags

    /// メニュー項目を識別するためのタグ
    private enum MenuItemTag: Int {
        case recording = 100
        case settings = 200
        case quit = 300
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")
        setupStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
    }

    // MARK: - Setup

    /// メニューバーのステータスアイテムを設定
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusItem = statusItem else {
            logger.error("Failed to create status item")
            return
        }

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let image = NSImage(
                systemSymbolName: "mic",
                accessibilityDescription: "WhisperPad"
            )?.withSymbolConfiguration(config)
            button.image = image
            button.toolTip = "WhisperPad - 音声文字起こし"
        }

        statusMenu = createMenu()
        statusItem.menu = statusMenu
        logger.info("Status item setup completed")
    }

    /// ドロップダウンメニューを作成
    /// - Returns: 設定済みの NSMenu
    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // 録音開始項目（現段階では無効）
        let recordingItem = NSMenuItem(
            title: "録音開始",
            action: nil,
            keyEquivalent: ""
        )
        recordingItem.tag = MenuItemTag.recording.rawValue
        recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        recordingItem.isEnabled = false
        menu.addItem(recordingItem)

        menu.addItem(NSMenuItem.separator())

        // 設定項目（現段階では無効）
        let settingsItem = NSMenuItem(
            title: "設定...",
            action: nil,
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.tag = MenuItemTag.settings.rawValue
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        settingsItem.isEnabled = false
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 終了項目
        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.tag = MenuItemTag.quit.rawValue
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    /// アプリケーションを終了
    @objc private func quitApplication() {
        logger.info("Quit application requested")
        NSApp.terminate(nil)
    }
}
