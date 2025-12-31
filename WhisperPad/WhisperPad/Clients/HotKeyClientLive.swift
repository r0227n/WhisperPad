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

    /// すべてのホットキーを解除
    func unregisterAll() {
        openSettingsHotKey = nil
        recordingToggleHotKey = nil
        pasteHotKey = nil
        cancelHotKey = nil
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
            unregisterAll: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterAll()
                }
            }
        )
    }
}
