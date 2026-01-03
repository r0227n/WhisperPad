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

    /// 現在のロケール（変更検出用）
    private var currentLocale: AppLocale?

    /// ロガー
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
        category: "AppDelegate"
    )

    /// ホットキークライアント
    @Dependency(\.hotKeyClient) var hotKeyClient

    /// 出力クライアント
    @Dependency(\.outputClient) var outputClient

    /// ホットキー再登録タスク（デバウンス用）
    private var hotKeyRegistrationTask: Task<Void, Never>?

    // MARK: - Property Accessors (for extensions)

    func getStatusItem() -> NSStatusItem? { statusItem }

    // Animation accessors
    func getAnimationTimer() -> Timer? { animationTimer }
    func setAnimationTimer(_ timer: Timer?) { animationTimer = timer }
    func getAnimationFrame() -> Int { animationFrame }
    func setAnimationFrame(_ frame: Int) { animationFrame = frame }
    func getAnimationIconConfig() -> StatusIconConfig? { animationIconConfig }
    func setAnimationIconConfig(_ config: StatusIconConfig?) { animationIconConfig = config }
    func getPulseTimer() -> Timer? { pulseTimer }
    func setPulseTimer(_ timer: Timer?) { pulseTimer = timer }
    func getPulsePhase() -> Double { pulsePhase }
    func setPulsePhase(_ phase: Double) { pulsePhase = phase }

    // HotKey registration task accessor
    func getHotKeyRegistrationTask() -> Task<Void, Never>? { hotKeyRegistrationTask }
    func setHotKeyRegistrationTask(_ task: Task<Void, Never>?) { hotKeyRegistrationTask = task }

    /// アプリ設定のロケールに基づいてローカライズされた文字列を取得
    func localizedAppString(forKey key: String) -> String {
        let languageCode: String

        if let identifier = store.settings.settings.general.preferredLocale.identifier {
            // ユーザーが明示的に言語を選択している場合（.en または .ja）
            languageCode = identifier
        } else {
            // .system の場合、システムの優先言語を使用
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            languageCode = Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
        }

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - Menu Item Tags

    /// メニュー項目を識別するためのタグ
    enum MenuItemTag: Int {
        case recording = 100
        case pauseResume = 101
        case settings = 200
        case quit = 300
        case micPermissionStatus = 400
        case notificationPermissionStatus = 500
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
        animationTimer?.invalidate()
        animationTimer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil

        // NotificationCenter オブザーバーを解除
        NotificationCenter.default.removeObserver(self, name: .hotKeySettingsChanged, object: nil)

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
            button.toolTip = localizedAppString(forKey: "app.tooltip")
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

            // Detect locale changes and rebuild menu
            let newLocale = self.store.settings.settings.general.preferredLocale
            if self.currentLocale != newLocale {
                self.currentLocale = newLocale
                self.rebuildMenu()
            }

            self.updateMenuForCurrentState()
            self.updateIconForCurrentState()
            self.updateTooltip()
        }
    }

    /// メニューを再構築
    private func rebuildMenu() {
        statusMenu = createMenu()
        statusMenu?.delegate = self
        statusItem?.menu = statusMenu
    }

    /// ツールチップを更新
    private func updateTooltip() {
        guard let button = statusItem?.button else { return }
        button.toolTip = localizedAppString(forKey: "app.tooltip")
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
    func setStatusIcon(symbolName: String, color: NSColor) {
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
        case .idle, .completed, .error:
            store.send(.startRecording)
        case .recording, .paused:
            store.send(.endRecording)
        case .transcribing:
            // 文字起こし中は何もしない
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
        default:
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

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        #if DEBUG
        updatePermissionMenuItems()
        updateOutputMenuItems()
        #endif
    }
}
