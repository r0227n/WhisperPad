//
//  AppDelegate.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Dependencies
import os.log
import UserNotifications

/// メニューバーアプリケーションを管理する AppDelegate
///
/// `NSStatusItem` を使用してメニューバーにアイコンを表示し、
/// TCA Store と連携してアプリの状態に応じた UI 更新を行います。
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// メニューバーに表示されるステータスアイテム
    private var statusItem: NSStatusItem?

    /// ステータスアイテムのメニュー
    var statusMenu: NSMenu?

    /// TCA Store
    let store: StoreOf<AppReducer>

    /// アニメーション用タイマー
    private var animationTimer: Timer?

    /// アニメーションフレーム番号
    private var animationFrame: Int = 0

    /// ロガー
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
        category: "AppDelegate"
    )

    /// ホットキークライアント
    @Dependency(\.hotKeyClient) private var hotKeyClient

    // MARK: - Menu Item Tags

    /// メニュー項目を識別するためのタグ
    enum MenuItemTag: Int {
        case recording = 100
        case pauseResume = 101
        case settings = 200
        case quit = 300
        case micPermissionStatus = 400
        case notificationPermissionStatus = 500
    }

    // MARK: - Initialization

    override init() {
        self.store = Store(initialState: AppReducer.State()) {
            AppReducer()
        }
        super.init()
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")
        setupStatusItem()
        setupObservation()
        requestNotificationPermission()
        setupHotKeys()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
        animationTimer?.invalidate()
        animationTimer = nil

        // ホットキーを解除
        Task {
            await hotKeyClient.unregisterOpenSettings()
        }
    }

    // MARK: - Setup

    /// メニューバーのステータスアイテムを設定
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusItem else {
            logger.error("Failed to create status item")
            return
        }

        if let button = statusItem.button {
            setStatusIcon(symbolName: "mic", color: .systemGray)
            button.toolTip = "WhisperPad - 音声文字起こし"
        }

        statusMenu = createMenu()
        statusMenu?.delegate = self
        statusItem.menu = statusMenu
        logger.info("Status item setup completed")
    }

    /// 状態監視を設定
    private func setupObservation() {
        observe { [weak self] in
            guard let self else { return }
            self.updateMenuForCurrentState()
            self.updateIconForCurrentState()
        }
    }

    /// 通知権限を要求
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
                if granted {
                    logger.info("Notification permission granted")
                } else {
                    logger.warning("Notification permission denied")
                }
            } catch {
                logger.error("Notification permission request failed: \(error.localizedDescription)")
            }
        }
    }

    /// グローバルホットキーを設定
    private func setupHotKeys() {
        Task {
            // アクセシビリティ権限をチェック
            let hasPermission = await hotKeyClient.checkAccessibilityPermission()

            if !hasPermission {
                logger.warning("Accessibility permission not granted, requesting...")
                await hotKeyClient.requestAccessibilityPermission()
            }

            // 設定画面を開くホットキーを登録 (⌘ + Shift + ,)
            await hotKeyClient.registerOpenSettings {
                Task { @MainActor in
                    NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
                }
            }
        }
    }

    // MARK: - Menu Creation

    /// ドロップダウンメニューを作成
    /// - Returns: 設定済みの NSMenu
    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // 録音項目
        let recordingItem = NSMenuItem(
            title: "録音開始",
            action: #selector(startRecording),
            keyEquivalent: ""
        )
        recordingItem.tag = MenuItemTag.recording.rawValue
        recordingItem.target = self
        recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        menu.addItem(recordingItem)

        // 一時停止/再開項目（録音中/一時停止中のみ表示）
        let pauseResumeItem = NSMenuItem(
            title: "一時停止",
            action: #selector(pauseRecording),
            keyEquivalent: ""
        )
        pauseResumeItem.tag = MenuItemTag.pauseResume.rawValue
        pauseResumeItem.target = self
        pauseResumeItem.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: nil)
        pauseResumeItem.isHidden = true
        menu.addItem(pauseResumeItem)

        menu.addItem(NSMenuItem.separator())

        // 設定項目
        let settingsItem = NSMenuItem(
            title: "設定...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.tag = MenuItemTag.settings.rawValue
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // デバッグメニュー（DEBUG ビルドのみ）
        #if DEBUG
        addDebugMenu(to: menu)
        menu.addItem(NSMenuItem.separator())
        #endif

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

    // MARK: - State-based UI Updates

    /// 現在の状態に応じてメニューを更新
    private func updateMenuForCurrentState() {
        guard let menu = statusMenu,
              let recordingItem = menu.item(withTag: MenuItemTag.recording.rawValue),
              let pauseResumeItem = menu.item(withTag: MenuItemTag.pauseResume.rawValue)
        else { return }

        switch store.appStatus {
        case .idle, .completed, .error:
            configureMenuItem(recordingItem, title: "録音開始", action: #selector(startRecording), symbol: "mic.fill")
            pauseResumeItem.isHidden = true

        case .recording:
            configureMenuItem(recordingItem, title: "録音終了", action: #selector(endRecording), symbol: "stop.fill")
            configureMenuItem(
                pauseResumeItem, title: "一時停止", action: #selector(pauseRecording), symbol: "pause.fill"
            )
            pauseResumeItem.isHidden = false

        case .paused:
            configureMenuItem(recordingItem, title: "録音終了", action: #selector(endRecording), symbol: "stop.fill")
            configureMenuItem(
                pauseResumeItem, title: "録音再開", action: #selector(resumeRecording), symbol: "play.fill"
            )
            pauseResumeItem.isHidden = false

        case .transcribing:
            configureMenuItem(recordingItem, title: "文字起こし中...", action: nil, symbol: "gear", isEnabled: false)
            pauseResumeItem.isHidden = true
        }
    }

    private func configureMenuItem(
        _ item: NSMenuItem,
        title: String,
        action: Selector?,
        symbol: String,
        isEnabled: Bool = true
    ) {
        item.title = title
        item.action = action
        item.target = action != nil ? self : nil
        item.isEnabled = isEnabled
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
    }

    /// 現在の状態に応じてアイコンを更新
    private func updateIconForCurrentState() {
        // transcribing 以外の状態ではアニメーションを停止
        if store.appStatus != .transcribing {
            stopGearAnimation()
        }

        switch store.appStatus {
        case .idle:
            setStatusIcon(symbolName: "mic", color: .systemGray)

        case .recording:
            setStatusIcon(symbolName: "mic.fill", color: .systemRed)

        case .paused:
            setStatusIcon(symbolName: "pause.fill", color: .systemOrange)

        case .transcribing:
            startGearAnimation()

        case .completed:
            setStatusIcon(symbolName: "checkmark.circle", color: .systemGreen)

        case .error:
            setStatusIcon(symbolName: "exclamationmark.triangle", color: .systemYellow)
        }
    }

    /// ステータスアイコンを設定
    /// - Parameters:
    ///   - symbolName: SF Symbol 名
    ///   - color: アイコンの色
    private func setStatusIcon(symbolName: String, color: NSColor) {
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "WhisperPad")
        button.image = image?.withSymbolConfiguration(config)
    }

    // MARK: - Actions

    /// 録音を開始
    @objc private func startRecording() {
        logger.info("Start recording requested")
        store.send(.startRecording)
    }

    /// 録音を終了
    @objc private func endRecording() {
        logger.info("End recording requested")
        store.send(.endRecording)
    }

    /// 録音を一時停止
    @objc private func pauseRecording() {
        logger.info("Pause recording requested")
        store.send(.pauseRecording)
    }

    /// 録音を再開
    @objc private func resumeRecording() {
        logger.info("Resume recording requested")
        store.send(.resumeRecording)
    }

    /// 設定画面を開く
    @objc private func openSettings() {
        logger.info("Open settings requested")

        // HiddenWindowView に通知を送信して Settings シーンを開く
        // macOS 14+ では @Environment(\.openSettings) を使用する必要があるため、
        // SwiftUI コンテキスト内から開く
        NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
    }

    /// アプリケーションを終了
    @objc private func quitApplication() {
        logger.info("Quit application requested")
        NSApp.terminate(nil)
    }
}

// MARK: - Animation

private extension AppDelegate {
    /// ギアアニメーションを開始
    func startGearAnimation() {
        guard animationTimer == nil else { return }

        animationFrame = 0
        setStatusIcon(symbolName: "gear", color: .systemBlue)

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateGearAnimationFrame()
        }
    }

    /// ギアアニメーションを停止
    func stopGearAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    /// ギアアニメーションのフレームを更新
    func updateGearAnimationFrame() {
        guard let button = statusItem?.button else { return }

        animationFrame = (animationFrame + 1) % 8

        // 色を少し変化させてアニメーション効果を出す
        let hue = CGFloat(animationFrame) / 8.0
        let color = NSColor(
            hue: 0.6 + hue * 0.1,
            saturation: 0.8,
            brightness: 0.9,
            alpha: 1.0
        )

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))

        let image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Processing")
        button.image = image?.withSymbolConfiguration(config)
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        #if DEBUG
        updatePermissionMenuItems()
        updateOutputMenuItems()
        #endif
    }
}
