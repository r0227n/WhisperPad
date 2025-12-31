//
//  AppDelegate.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Dependencies
import os.log
import UserNotifications

// MARK: - Notification.Name Extension

extension Notification.Name {
    /// ホットキー設定が変更された通知
    static let hotKeySettingsChanged = Notification.Name("hotKeySettingsChanged")

    /// ストリーミングポップアップを閉じる通知
    static let closeStreamingPopup = Notification.Name("closeStreamingPopup")
}

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
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
        category: "AppDelegate"
    )

    /// ホットキークライアント
    @Dependency(\.hotKeyClient) var hotKeyClient

    /// 出力クライアント
    @Dependency(\.outputClient) var outputClient

    /// ストリーミングポップアップウィンドウ
    private var streamingPopupWindow: StreamingPopupWindow?

    // MARK: - Property Accessors (for extensions)

    func getStatusItem() -> NSStatusItem? { statusItem }
    func getStreamingPopupWindow() -> StreamingPopupWindow? { streamingPopupWindow }
    func setStreamingPopupWindow(_ window: StreamingPopupWindow?) { streamingPopupWindow = window }

    // MARK: - Menu Item Tags

    /// メニュー項目を識別するためのタグ
    enum MenuItemTag: Int {
        case recording = 100
        case pauseResume = 101
        case settings = 200
        case quit = 300
        case micPermissionStatus = 400
        case notificationPermissionStatus = 500
        case streaming = 600
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
        setupHotKeyObserver()
        requestNotificationPermission()
        setupHotKeys()
        setupStreamingPopupObserver()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
        animationTimer?.invalidate()
        animationTimer = nil

        // ストリーミングポップアップを閉じる
        closeStreamingPopup()

        // NotificationCenter オブザーバーを解除
        NotificationCenter.default.removeObserver(self, name: .hotKeySettingsChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .closeStreamingPopup, object: nil)

        // ホットキーを解除
        Task {
            await hotKeyClient.unregisterAll()
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

    // MARK: - State-based UI Updates

    /// 現在の状態に応じてメニューを更新
    private func updateMenuForCurrentState() {
        guard let menu = statusMenu,
              let recordingItem = menu.item(withTag: MenuItemTag.recording.rawValue),
              let pauseResumeItem = menu.item(withTag: MenuItemTag.pauseResume.rawValue),
              let streamingItem = menu.item(withTag: MenuItemTag.streaming.rawValue)
        else { return }

        switch store.appStatus {
        case .idle, .completed, .error, .streamingCompleted:
            // 録音・ストリーミングどちらも有効
            configureMenuItem(recordingItem, title: "録音開始", action: #selector(startRecording), symbol: "mic.fill")
            streamingItem.isEnabled = true
            pauseResumeItem.isHidden = true

        case .recording:
            // 録音中はストリーミング無効
            configureMenuItem(recordingItem, title: "録音終了", action: #selector(endRecording), symbol: "stop.fill")
            configureMenuItem(
                pauseResumeItem, title: "一時停止", action: #selector(pauseRecording), symbol: "pause.fill"
            )
            pauseResumeItem.isHidden = false
            streamingItem.isEnabled = false

        case .paused:
            // 一時停止中もストリーミング無効
            configureMenuItem(recordingItem, title: "録音終了", action: #selector(endRecording), symbol: "stop.fill")
            configureMenuItem(
                pauseResumeItem, title: "録音再開", action: #selector(resumeRecording), symbol: "play.fill"
            )
            pauseResumeItem.isHidden = false
            streamingItem.isEnabled = false

        case .transcribing:
            // 文字起こし中はストリーミング無効
            configureMenuItem(recordingItem, title: "文字起こし中...", action: nil, symbol: "gear", isEnabled: false)
            pauseResumeItem.isHidden = true
            streamingItem.isEnabled = false

        case .streamingTranscribing:
            // ストリーミング中は録音とストリーミング両方無効
            configureMenuItem(
                recordingItem,
                title: "ストリーミング中...",
                action: nil,
                symbol: "waveform.badge.mic",
                isEnabled: false
            )
            pauseResumeItem.isHidden = true
            streamingItem.isEnabled = false
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

        case .paused:
            setStatusIcon(symbolName: "pause.fill", color: .systemOrange)

        case .transcribing:
            startGearAnimation()

        case .completed:
            setStatusIcon(symbolName: "checkmark.circle", color: .systemGreen)

        case .streamingTranscribing:
            setStatusIcon(symbolName: "waveform.badge.mic", color: .systemPurple)

        case .streamingCompleted:
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

    /// 録音をトグル（開始/停止）
    func toggleRecording() {
        logger.info("Toggle recording hotkey triggered: ⌥␣")
        switch store.appStatus {
        case .idle, .completed, .error, .streamingCompleted:
            store.send(.startRecording)
        case .recording, .paused:
            store.send(.endRecording)
        case .transcribing, .streamingTranscribing:
            // 文字起こし中・ストリーミング中は何もしない
            break
        }
    }

    /// 最後の書き起こしをペースト
    func pasteLastTranscription() {
        logger.info("Paste hotkey triggered: ⌘⇧V")
        guard let text = store.lastTranscription, !text.isEmpty else {
            logger.warning("No transcription to paste")
            return
        }
        Task {
            _ = await outputClient.copyToClipboard(text)
            await outputClient.showNotification("WhisperPad", "クリップボードにコピーしました")
        }
    }

    /// 録音をキャンセル
    func cancelRecording() {
        // 録音中または一時停止中のみキャンセル可能
        guard store.appStatus == .recording || store.appStatus == .paused else {
            return
        }
        logger.info("Cancel recording hotkey triggered: Escape")
        store.send(.cancelRecording)
    }

    // MARK: - Streaming Actions

    /// ストリーミング文字起こしを開始
    @objc private func startStreaming() {
        logger.info("Start streaming transcription requested")
        showStreamingPopup()
        store.send(.startStreamingTranscription)
    }

    /// ストリーミングをトグル（ホットキー用）
    func toggleStreaming() {
        logger.info("Toggle streaming hotkey triggered: ⌘⇧R")
        switch store.appStatus {
        case .idle, .completed, .error, .streamingCompleted:
            startStreaming()
        case .streamingTranscribing:
            // ストリーミング中は停止
            store.send(.streamingTranscription(.stopButtonTapped))
        case .recording, .paused, .transcribing:
            // 録音中・文字起こし中は何もしない
            break
        }
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
