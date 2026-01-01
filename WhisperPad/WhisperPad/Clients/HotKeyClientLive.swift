//
//  HotKeyClientLive.swift
//  WhisperPad
//

import AppKit
import ApplicationServices
import Dependencies
import HotKey
import OSLog

nonisolated(unsafe) private let logger = Logger(
    subsystem: "com.whisperpad",
    category: "HotKeyClientLive"
)

/// ホットキーインスタンスを保持するアクター
///
/// HotKey インスタンスはメインスレッドで保持し、
/// 解放されないようにする必要があります。
@MainActor
private final class HotKeyManager {
    static let shared = HotKeyManager()

    private var openSettingsHotKey: HotKey?
    private var recordingToggleHotKey: HotKey?
    private var pasteHotKey: HotKey?
    private var cancelHotKey: HotKey?
    private var streamingHotKey: HotKey?
    private var recordingToggleKey: HotKey?
    private var recordingPauseHotKey: HotKey?

    private init() {}

    // MARK: - Open Settings (⌘⇧,)

    /// 設定画面を開くホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerOpenSettings(handler: @escaping () -> Void) {
        openSettingsHotKey = nil
        let hotKey = HotKey(key: .comma, modifiers: [.command, .shift])
        hotKey.keyDownHandler = handler
        openSettingsHotKey = hotKey
        logger.info("Open settings hotkey registered: ⌘⇧,")
    }

    /// 設定画面を開くホットキーを解除
    func unregisterOpenSettings() {
        openSettingsHotKey = nil
        logger.info("Open settings hotkey unregistered")
    }

    // MARK: - Recording Toggle (⌥⇧ Space)

    /// 録音トグルホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerRecordingToggle(handler: @escaping () -> Void) {
        recordingToggleHotKey = nil
        let hotKey = HotKey(key: .space, modifiers: [.option, .shift])
        hotKey.keyDownHandler = handler
        recordingToggleHotKey = hotKey
        logger.info("Recording toggle hotkey registered: ⌥⇧␣")
    }

    /// 録音トグルホットキーを解除
    func unregisterRecordingToggle() {
        recordingToggleHotKey = nil
        logger.info("Recording toggle hotkey unregistered")
    }

    // MARK: - Paste (⌘⇧V)

    /// ペーストホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerPaste(handler: @escaping () -> Void) {
        pasteHotKey = nil
        let hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        hotKey.keyDownHandler = handler
        pasteHotKey = hotKey
        logger.info("Paste hotkey registered: ⌘⇧V")
    }

    /// ペーストホットキーを解除
    func unregisterPaste() {
        pasteHotKey = nil
        logger.info("Paste hotkey unregistered")
    }

    // MARK: - Cancel (Escape)

    /// 録音キャンセルホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerCancel(handler: @escaping () -> Void) {
        cancelHotKey = nil
        let hotKey = HotKey(key: .escape, modifiers: [])
        hotKey.keyDownHandler = handler
        cancelHotKey = hotKey
        logger.info("Cancel hotkey registered: Escape")
    }

    /// 録音キャンセルホットキーを解除
    func unregisterCancel() {
        cancelHotKey = nil
        logger.info("Cancel hotkey unregistered")
    }

    // MARK: - 動的キーコンボ対応

    /// 動的キーコンボで録音ホットキーを登録（Push-to-Talk対応）
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - keyDownHandler: キーが押されたときのハンドラー
    ///   - keyUpHandler: キーが離されたときのハンドラー（Push-to-Talk用）
    func registerRecordingWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        keyDownHandler: @escaping () -> Void,
        keyUpHandler: @escaping () -> Void
    ) {
        recordingToggleHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = keyDownHandler
        hotKey.keyUpHandler = keyUpHandler
        recordingToggleHotKey = hotKey
        logger
            .info(
                "Recording hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
            )
    }

    /// 動的キーコンボでペーストホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerPasteWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        pasteHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        pasteHotKey = hotKey
        logger.info("Paste hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)")
    }

    /// 動的キーコンボで設定を開くホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerOpenSettingsWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        openSettingsHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        openSettingsHotKey = hotKey
        logger.info(
            "Open settings hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// 動的キーコンボでキャンセルホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerCancelWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        cancelHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        cancelHotKey = hotKey
        logger.info(
            "Cancel hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    // MARK: - Streaming (⌘⇧R)

    /// 動的キーコンボでストリーミングホットキーを登録（Push-to-Talk対応）
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - keyDownHandler: キーが押されたときのハンドラー
    ///   - keyUpHandler: キーが離されたときのハンドラー（Push-to-Talk用）
    func registerStreamingWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        keyDownHandler: @escaping () -> Void,
        keyUpHandler: @escaping () -> Void
    ) {
        streamingHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = keyDownHandler
        hotKey.keyUpHandler = keyUpHandler
        streamingHotKey = hotKey
        logger.info(
            "Streaming hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// ストリーミングホットキーを解除
    func unregisterStreaming() {
        streamingHotKey = nil
        logger.info("Streaming hotkey unregistered")
    }

    // MARK: - Recording Toggle (⌥⇧S)

    /// 動的キーコンボで録音開始/終了トグルホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerRecordingToggleWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        recordingToggleKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        recordingToggleKey = hotKey
        logger.info(
            "Recording toggle hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    // MARK: - Recording Pause (⌥⇧P)

    /// 動的キーコンボで録音一時停止ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerRecordingPauseWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        recordingPauseHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        recordingPauseHotKey = hotKey
        logger.info(
            "Recording pause hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// すべてのホットキーを解除
    func unregisterAll() {
        openSettingsHotKey = nil
        recordingToggleHotKey = nil
        pasteHotKey = nil
        cancelHotKey = nil
        streamingHotKey = nil
        recordingToggleKey = nil
        recordingPauseHotKey = nil
        logger.info("All hotkeys unregistered")
    }
}

// MARK: - DependencyKey

extension HotKeyClient: DependencyKey {
    static var liveValue: Self {
        Self(
            registerOpenSettings: { handler in
                await MainActor.run {
                    HotKeyManager.shared.registerOpenSettings(handler: handler)
                }
            },
            unregisterOpenSettings: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterOpenSettings()
                }
            },
            checkAccessibilityPermission: {
                let trusted = AXIsProcessTrusted()
                logger.info("Accessibility permission: \(trusted ? "granted" : "denied")")
                return trusted
            },
            requestAccessibilityPermission: {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
                logger.info("Accessibility permission requested, current status: \(trusted)")
            },
            registerRecordingToggle: { handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingToggle(handler: handler)
                }
            },
            unregisterRecordingToggle: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterRecordingToggle()
                }
            },
            registerPaste: { handler in
                await MainActor.run {
                    HotKeyManager.shared.registerPaste(handler: handler)
                }
            },
            unregisterPaste: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterPaste()
                }
            },
            registerCancel: { handler in
                await MainActor.run {
                    HotKeyManager.shared.registerCancel(handler: handler)
                }
            },
            unregisterCancel: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterCancel()
                }
            },
            registerRecordingWithCombo: { combo, keyDownHandler, keyUpHandler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingWithCombo(
                        combo,
                        keyDownHandler: keyDownHandler,
                        keyUpHandler: keyUpHandler
                    )
                }
            },
            registerPasteWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerPasteWithCombo(combo, handler: handler)
                }
            },
            registerOpenSettingsWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerOpenSettingsWithCombo(combo, handler: handler)
                }
            },
            registerCancelWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerCancelWithCombo(combo, handler: handler)
                }
            },
            unregisterAll: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterAll()
                }
            },
            registerStreamingWithCombo: { combo, keyDownHandler, keyUpHandler in
                await MainActor.run {
                    HotKeyManager.shared.registerStreamingWithCombo(
                        combo,
                        keyDownHandler: keyDownHandler,
                        keyUpHandler: keyUpHandler
                    )
                }
            },
            unregisterStreaming: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterStreaming()
                }
            },
            registerRecordingToggleWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingToggleWithCombo(combo, handler: handler)
                }
            },
            registerRecordingPauseWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingPauseWithCombo(combo, handler: handler)
                }
            }
        )
    }
}
