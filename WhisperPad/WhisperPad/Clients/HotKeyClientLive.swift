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

    private var recordingToggleHotKey: HotKey?
    private var cancelHotKey: HotKey?
    private var streamingHotKey: HotKey?
    private var recordingPauseHotKey: HotKey?

    private init() {}

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

    /// 動的キーコンボで録音ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerRecordingWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        recordingToggleHotKey = nil
        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        recordingToggleHotKey = hotKey
        logger
            .info(
                "Recording hotkey registered with combo: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
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
            "Recording pause hotkey registered: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// すべてのホットキーを解除
    func unregisterAll() {
        recordingToggleHotKey = nil
        cancelHotKey = nil
        streamingHotKey = nil
        recordingPauseHotKey = nil
        logger.info("All hotkeys unregistered")
    }
}

// MARK: - DependencyKey

extension HotKeyClient: DependencyKey {
    static var liveValue: Self {
        Self(
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
            registerRecordingWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingWithCombo(combo, handler: handler)
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
            registerRecordingPauseWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingPauseWithCombo(combo, handler: handler)
                }
            }
        )
    }
}
