//
//  HotKeyClientLive.swift
//  WhisperPad
//

import AppKit
import ApplicationServices
import Dependencies
import HotKey
import OSLog

private let logger = Logger(
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
    private var recordingPauseHotKey: HotKey?

    /// 解放待ちのHotKeyインスタンスを一時保持（遅延解放用）
    private var pendingDeallocation: [HotKey] = []

    private init() {}

    /// 古いHotKeyインスタンスを遅延解放する共通処理
    private func scheduleDeallocation(_ oldHotKey: HotKey) {
        pendingDeallocation.append(oldHotKey)
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                if let index = self.pendingDeallocation.firstIndex(where: { $0 === oldHotKey }) {
                    self.pendingDeallocation.remove(at: index)
                }
            }
        }
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
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            break
        case let .failure(error):
            logger.error("""
            Cannot register recording hotkey: \(error). \
            keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
            """)
            return
        }

        if let oldHotKey = recordingToggleHotKey { scheduleDeallocation(oldHotKey) }
        recordingToggleHotKey = nil

        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        recordingToggleHotKey = hotKey
        logger.info(
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
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            break
        case let .failure(error):
            logger.error(
                "Cannot register cancel hotkey: \(error). keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
            )
            return
        }

        if let oldHotKey = cancelHotKey { scheduleDeallocation(oldHotKey) }
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

    // MARK: - Recording Pause (⌥⇧P)

    /// 動的キーコンボで録音一時停止ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerRecordingPauseWithCombo(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            break
        case let .failure(error):
            logger.error("""
            Cannot register recording pause hotkey: \(error). \
            keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
            """)
            return
        }

        if let oldHotKey = recordingPauseHotKey { scheduleDeallocation(oldHotKey) }
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
            registerRecordingPauseWithCombo: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerRecordingPauseWithCombo(combo, handler: handler)
                }
            }
        )
    }
}
