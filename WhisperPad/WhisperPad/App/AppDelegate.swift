//
//  AppDelegate.swift
//  WhisperPad
//

import AppKit
import AVFoundation
import ComposableArchitecture
import Dependencies
import os.log

/// メニューバーアプリケーションを管理する AppDelegate
///
/// `NSStatusItem` を使用してメニューバーにアイコンを表示し、
/// TCA Store と連携してアプリの状態に応じた UI 更新を行います。
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// メニューバーに表示されるステータスアイテム
    private var statusItem: NSStatusItem?

    /// ステータスアイテムのメニュー
    private var statusMenu: NSMenu?

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

    // MARK: - Menu Item Tags

    /// メニュー項目を識別するためのタグ
    private enum MenuItemTag: Int {
        case recording = 100
        case settings = 200
        case quit = 300
        case micPermissionStatus = 400
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
        animationTimer?.invalidate()
        animationTimer = nil
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
              let recordingItem = menu.item(withTag: MenuItemTag.recording.rawValue)
        else { return }

        switch store.appStatus {
        case .idle:
            recordingItem.title = "録音開始"
            recordingItem.action = #selector(startRecording)
            recordingItem.target = self
            recordingItem.isEnabled = true
            recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)

        case .recording:
            recordingItem.title = "録音停止"
            recordingItem.action = #selector(stopRecording)
            recordingItem.target = self
            recordingItem.isEnabled = true
            recordingItem.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: nil)

        case .transcribing:
            recordingItem.title = "文字起こし中..."
            recordingItem.action = nil
            recordingItem.isEnabled = false
            recordingItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)

        case .completed:
            recordingItem.title = "録音開始"
            recordingItem.action = #selector(startRecording)
            recordingItem.target = self
            recordingItem.isEnabled = true
            recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)

        case .error:
            recordingItem.title = "録音開始"
            recordingItem.action = #selector(startRecording)
            recordingItem.target = self
            recordingItem.isEnabled = true
            recordingItem.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)
        }
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

    /// 録音を停止
    @objc private func stopRecording() {
        logger.info("Stop recording requested")
        store.send(.stopRecording)
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
        #endif
    }
}

// MARK: - Debug Menu and Actions

#if DEBUG
private extension AppDelegate {
    /// デバッグメニューを追加
    func addDebugMenu(to menu: NSMenu) {
        let debugMenu = NSMenu(title: "Debug")

        let debugIdle = NSMenuItem(
            title: "Set Idle",
            action: #selector(debugSetIdle),
            keyEquivalent: ""
        )
        debugIdle.target = self
        debugMenu.addItem(debugIdle)

        let debugRecording = NSMenuItem(
            title: "Set Recording",
            action: #selector(debugSetRecording),
            keyEquivalent: ""
        )
        debugRecording.target = self
        debugMenu.addItem(debugRecording)

        let debugTranscribing = NSMenuItem(
            title: "Set Transcribing",
            action: #selector(debugSetTranscribing),
            keyEquivalent: ""
        )
        debugTranscribing.target = self
        debugMenu.addItem(debugTranscribing)

        let debugCompleted = NSMenuItem(
            title: "Set Completed",
            action: #selector(debugSetCompleted),
            keyEquivalent: ""
        )
        debugCompleted.target = self
        debugMenu.addItem(debugCompleted)

        let debugError = NSMenuItem(
            title: "Set Error",
            action: #selector(debugSetError),
            keyEquivalent: ""
        )
        debugError.target = self
        debugMenu.addItem(debugError)

        // Permissions サブメニュー
        debugMenu.addItem(NSMenuItem.separator())
        addPermissionsSubmenu(to: debugMenu)

        // WhisperKit サブメニュー
        debugMenu.addItem(NSMenuItem.separator())
        addWhisperKitSubmenu(to: debugMenu)

        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        menu.addItem(debugItem)
    }

    /// Permissions サブメニューを追加
    func addPermissionsSubmenu(to debugMenu: NSMenu) {
        let permissionsMenu = NSMenu(title: "Permissions")

        // マイク権限状態（動的タイトル）
        let micStatusItem = NSMenuItem(
            title: "Microphone: Checking...",
            action: nil,
            keyEquivalent: ""
        )
        micStatusItem.tag = MenuItemTag.micPermissionStatus.rawValue
        permissionsMenu.addItem(micStatusItem)

        // マイク権限リクエスト
        let requestMicItem = NSMenuItem(
            title: "Request Microphone Permission",
            action: #selector(debugRequestMicrophonePermission),
            keyEquivalent: ""
        )
        requestMicItem.target = self
        permissionsMenu.addItem(requestMicItem)

        // マイク設定を開く
        let openMicSettingsItem = NSMenuItem(
            title: "Open Microphone Settings...",
            action: #selector(debugOpenMicrophoneSettings),
            keyEquivalent: ""
        )
        openMicSettingsItem.target = self
        permissionsMenu.addItem(openMicSettingsItem)

        let permissionsItem = NSMenuItem(title: "Permissions", action: nil, keyEquivalent: "")
        permissionsItem.submenu = permissionsMenu
        debugMenu.addItem(permissionsItem)
    }

    @objc func debugSetIdle() {
        logger.debug("Debug: Set Idle")
        store.send(.resetToIdle)
    }

    @objc func debugSetRecording() {
        logger.debug("Debug: Set Recording")
        store.send(.startRecording)
    }

    @objc func debugSetTranscribing() {
        logger.debug("Debug: Set Transcribing")
        store.send(.stopRecording)
    }

    @objc func debugSetCompleted() {
        logger.debug("Debug: Set Completed")
        store.send(.transcriptionCompleted("Debug transcription text"))
    }

    @objc func debugSetError() {
        logger.debug("Debug: Set Error")
        store.send(.errorOccurred("Debug error message"))
    }

    // MARK: - Permission Debug Actions

    @objc func debugRequestMicrophonePermission() {
        logger.debug("Debug: Requesting microphone permission")
        // アプリをアクティブ化してダイアログを前面に表示
        NSApp.activate(ignoringOtherApps: true)
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            self?.logger.debug("Debug: Microphone permission result: \(granted)")
            DispatchQueue.main.async {
                self?.updatePermissionMenuItems()
            }
        }
    }

    @objc func debugOpenMicrophoneSettings() {
        logger.debug("Debug: Opening microphone settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 権限メニュー項目を更新
    func updatePermissionMenuItems() {
        guard let menu = statusItem?.menu else { return }

        // Debug メニューを探す
        for item in menu.items {
            guard let submenu = item.submenu, submenu.title == "Debug" else { continue }
            // Permissions サブメニューを探す
            for debugItem in submenu.items {
                guard let permMenu = debugItem.submenu, permMenu.title == "Permissions" else { continue }

                // マイク権限状態を更新
                if let micItem = permMenu.item(withTag: MenuItemTag.micPermissionStatus.rawValue) {
                    let status = AVCaptureDevice.authorizationStatus(for: .audio)
                    micItem.title = "Microphone: \(statusEmoji(for: status)) \(statusText(for: status))"
                }
            }
        }
    }

    private func statusEmoji(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "✅"
        case .denied: return "❌"
        case .restricted: return "🚫"
        case .notDetermined: return "❓"
        @unknown default: return "❓"
        }
    }

    private func statusText(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - WhisperKit Debug Menu

    /// WhisperKit サブメニューを追加
    func addWhisperKitSubmenu(to debugMenu: NSMenu) {
        let whisperKitMenu = NSMenu(title: "WhisperKit")

        // モデル一覧を取得
        let fetchModelsItem = NSMenuItem(
            title: "Fetch Available Models",
            action: #selector(debugFetchAvailableModels),
            keyEquivalent: ""
        )
        fetchModelsItem.target = self
        whisperKitMenu.addItem(fetchModelsItem)

        // 推奨モデルを取得
        let recommendedModelItem = NSMenuItem(
            title: "Get Recommended Model",
            action: #selector(debugGetRecommendedModel),
            keyEquivalent: ""
        )
        recommendedModelItem.target = self
        whisperKitMenu.addItem(recommendedModelItem)

        whisperKitMenu.addItem(NSMenuItem.separator())

        // tiny モデルをダウンロード
        let downloadTinyItem = NSMenuItem(
            title: "Download tiny Model",
            action: #selector(debugDownloadTinyModel),
            keyEquivalent: ""
        )
        downloadTinyItem.target = self
        whisperKitMenu.addItem(downloadTinyItem)

        let whisperKitItem = NSMenuItem(title: "WhisperKit", action: nil, keyEquivalent: "")
        whisperKitItem.submenu = whisperKitMenu
        debugMenu.addItem(whisperKitItem)
    }

    // MARK: - WhisperKit Debug Actions

    @objc func debugFetchAvailableModels() {
        logger.debug("Debug: Fetching available models")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            do {
                let models = try await transcriptionClient.fetchAvailableModels()
                logger.info("Debug: Found \(models.count) models")
                for model in models {
                    logger.info("  - \(model)")
                }
                await MainActor.run {
                    showAlert(
                        title: "Available Models",
                        message: "Found \(models.count) models:\n\n\(models.joined(separator: "\n"))"
                    )
                }
            } catch {
                logger.error("Debug: Failed to fetch models: \(error.localizedDescription)")
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to fetch models: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func debugGetRecommendedModel() {
        logger.debug("Debug: Getting recommended model")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            let recommended = await transcriptionClient.recommendedModel()
            logger.info("Debug: Recommended model: \(recommended)")
            await MainActor.run {
                showAlert(title: "Recommended Model", message: recommended)
            }
        }
    }

    @objc func debugDownloadTinyModel() {
        logger.debug("Debug: Downloading tiny model")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            do {
                await MainActor.run {
                    showAlert(
                        title: "Downloading",
                        message: "Downloading openai_whisper-tiny model...\nThis may take a while."
                    )
                }
                let url = try await transcriptionClient.downloadModel("openai_whisper-tiny") { progress in
                    self.logger.debug("Debug: Download progress: \(Int(progress * 100))%")
                }
                logger.info("Debug: Model downloaded to: \(url.path)")
                await MainActor.run {
                    showAlert(
                        title: "Download Complete",
                        message: "Model downloaded to:\n\(url.path)"
                    )
                }
            } catch {
                logger.error("Debug: Failed to download model: \(error.localizedDescription)")
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to download model: \(error.localizedDescription)")
                }
            }
        }
    }

    /// アラートを表示
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
#endif
