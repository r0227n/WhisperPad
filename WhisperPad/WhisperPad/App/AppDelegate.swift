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

    /// アニメーション中のアイコン設定
    private var animationIconConfig: StatusIconConfig?

    /// パルスアニメーション用タイマー
    private var pulseTimer: Timer?

    /// パルスアニメーションのフェーズ（ラジアン）
    private var pulsePhase: Double = 0

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
        case cancel = 700
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

        // WhisperKit をバックグラウンドで初期化
        store.send(.initializeWhisperKit)
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
        animationTimer?.invalidate()
        animationTimer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil

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
    @MainActor
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

    /// 現在の状態に応じてアイコンを更新
    private func updateIconForCurrentState() {
        // カスタムアイコン設定を取得
        let iconSettings = store.settings.settings.general.menuBarIconSettings

        switch store.appStatus {
        case .idle:
            stopAllAnimations()
            let config = iconSettings.idle
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()

        case .recording:
            stopGearAnimation()
            let config = iconSettings.recording
            startPulseAnimation(with: config)
            setRecordingTimeDisplay(store.recording.currentDuration)

        case .paused:
            stopAllAnimations()
            let config = iconSettings.paused
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            setRecordingTimeDisplay(store.recording.currentDuration)

        case .transcribing:
            stopPulseAnimation()
            let config = iconSettings.transcribing
            startGearAnimation(with: config)
            clearRecordingTimeDisplay()

        case .completed:
            stopAllAnimations()
            let config = iconSettings.completed
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()

        case .streamingTranscribing:
            stopGearAnimation()
            let config = iconSettings.streamingTranscribing
            startPulseAnimation(with: config)
            setRecordingTimeDisplay(store.streamingTranscription.duration)

        case .streamingCompleted:
            stopAllAnimations()
            let config = iconSettings.streamingCompleted
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()

        case .error:
            stopAllAnimations()
            let config = iconSettings.error
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()
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

    // MARK: - Recording Time Display

    /// 録音時間を「MM:SS」形式でフォーマット
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// ステータスバーに録音時間を表示
    private func setRecordingTimeDisplay(_ duration: TimeInterval) {
        guard let button = statusItem?.button else { return }
        // 等幅数字フォントで表示（数字幅が変わっても揃う）
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        ]
        button.attributedTitle = NSAttributedString(
            string: formatDuration(duration),
            attributes: attributes
        )
    }

    /// ステータスバーから録音時間表示をクリア
    private func clearRecordingTimeDisplay() {
        statusItem?.button?.title = ""
    }

    // MARK: - Actions

    /// 録音を開始
    @objc func startRecording() {
        logger.info("Start recording requested")
        store.send(.startRecording)
    }

    /// 録音を終了
    @objc func endRecording() {
        logger.info("End recording requested")
        store.send(.endRecording)
    }

    /// 録音を一時停止
    @objc func pauseRecording() {
        logger.info("Pause recording requested")
        store.send(.pauseRecording)
    }

    /// 録音を再開
    @objc func resumeRecording() {
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

    /// 録音をキャンセル（ホットキー用）
    func cancelRecording() {
        // 録音中または一時停止中のみキャンセル可能
        guard store.appStatus == .recording || store.appStatus == .paused else {
            return
        }
        logger.info("Cancel recording hotkey triggered: Escape")
        store.send(.cancelRecording)
    }

    /// キャンセルメニュー項目がタップされた
    @objc func cancelMenuItemTapped() {
        logger.info("Cancel menu item tapped")
        switch store.appStatus {
        case .recording, .paused:
            store.send(.cancelRecording)
        case .streamingTranscribing:
            store.send(.streamingTranscription(.cancelButtonTapped))
        default:
            break
        }
    }

    // MARK: - Streaming Actions

    /// ストリーミング文字起こしを開始
    @objc func startStreaming() {
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
    @objc func openSettings() {
        logger.info("Open settings requested")

        // HiddenWindowView に通知を送信して Settings シーンを開く
        // macOS 14+ では @Environment(\.openSettings) を使用する必要があるため、
        // SwiftUI コンテキスト内から開く
        NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
    }

    /// アプリケーションを終了
    @objc func quitApplication() {
        logger.info("Quit application requested")
        NSApp.terminate(nil)
    }
}

// MARK: - Animation

private extension AppDelegate {
    /// アイコンアニメーションを開始
    /// - Parameter iconConfig: アニメーションに使用するアイコン設定
    func startGearAnimation(with iconConfig: StatusIconConfig) {
        guard animationTimer == nil else { return }

        animationFrame = 0
        animationIconConfig = iconConfig
        setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateGearAnimationFrame()
        }
    }

    /// ギアアニメーションを停止
    func stopGearAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationIconConfig = nil
    }

    /// アイコンアニメーションのフレームを更新
    func updateGearAnimationFrame() {
        guard let button = statusItem?.button,
              let iconConfig = animationIconConfig else { return }

        animationFrame = (animationFrame + 1) % 8

        // ベースカラーのHSB値を取得して色相を変化させる
        let baseColor = iconConfig.color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if let convertedColor = baseColor.usingColorSpace(.deviceRGB) {
            convertedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        } else {
            // フォールバック: デフォルトの青系
            hue = 0.6
            saturation = 0.8
            brightness = 0.9
            alpha = 1.0
        }

        // 色相を少し変化させてアニメーション効果を出す
        let animatedHue = hue + (CGFloat(animationFrame) / 8.0) * 0.1
        let color = NSColor(
            hue: animatedHue.truncatingRemainder(dividingBy: 1.0),
            saturation: saturation,
            brightness: brightness,
            alpha: alpha
        )

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))

        let image = NSImage(systemSymbolName: iconConfig.symbolName, accessibilityDescription: "Processing")
        button.image = image?.withSymbolConfiguration(config)
    }

    // MARK: - Pulse Animation

    /// パルスアニメーションを開始
    /// - Parameter iconConfig: アニメーションに使用するアイコン設定
    func startPulseAnimation(with iconConfig: StatusIconConfig) {
        guard pulseTimer == nil else { return }

        // Reduce Motion チェック
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)
            return
        }

        pulsePhase = 0
        setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)

        // 0.8s cycle / 20 frames = 0.04s interval
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            self?.updatePulseAnimationFrame()
        }
    }

    /// パルスアニメーションのフレームを更新
    func updatePulseAnimationFrame() {
        guard let button = statusItem?.button else { return }

        // Sine wave: 0.5 to 1.0
        pulsePhase += 0.04 / 0.8 * 2 * .pi  // Complete cycle in 0.8s
        let opacity = 0.75 + 0.25 * sin(pulsePhase)  // Range: 0.5 to 1.0
        button.alphaValue = CGFloat(opacity)
    }

    /// パルスアニメーションを停止
    func stopPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        statusItem?.button?.alphaValue = 1.0
    }

    /// すべてのアニメーションを停止
    func stopAllAnimations() {
        stopGearAnimation()
        stopPulseAnimation()
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
