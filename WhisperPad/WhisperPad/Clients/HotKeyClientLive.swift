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
    private var streamingHotKey: HotKey?
    private var recordingPauseHotKey: HotKey?
    private var popupCopyAndCloseHotKey: HotKey?
    private var popupSaveToFileHotKey: HotKey?
    private var popupCloseHotKey: HotKey?

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
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register recording hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
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
        logger
            .info(
                """
                Recording hotkey registered with combo: \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
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
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register cancel hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
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
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register streaming hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
            return
        }

        if let oldHotKey = streamingHotKey { scheduleDeallocation(oldHotKey) }
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
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register recording pause hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
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
        streamingHotKey = nil
        recordingPauseHotKey = nil
        popupCopyAndCloseHotKey = nil
        popupSaveToFileHotKey = nil
        popupCloseHotKey = nil
        logger.info("All hotkeys unregistered")
    }

    // MARK: - Popup Hotkeys

    /// ポップアップ: コピーして閉じるホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerPopupCopyAndClose(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register popup copy & close hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
            return
        }

        if let oldHotKey = popupCopyAndCloseHotKey { scheduleDeallocation(oldHotKey) }
        popupCopyAndCloseHotKey = nil

        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        popupCopyAndCloseHotKey = hotKey
        logger.info(
            "Popup copy & close hotkey registered: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// ポップアップ: ファイル保存ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerPopupSaveToFile(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register popup save to file hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
            return
        }

        if let oldHotKey = popupSaveToFileHotKey { scheduleDeallocation(oldHotKey) }
        popupSaveToFileHotKey = nil

        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        popupSaveToFileHotKey = hotKey
        logger.info(
            "Popup save to file hotkey registered: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// ポップアップ: 閉じるホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerPopupClose(
        _ combo: HotKeySettings.KeyComboSettings,
        handler: @escaping () -> Void
    ) {
        // Validate BEFORE attempting to create HotKey instance
        let validation = HotKeyValidator.canRegister(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )

        switch validation {
        case .success:
            // Validation passed, proceed with registration
            break
        case let .failure(error):
            logger.error(
                """
                Cannot register popup close hotkey: \(error). \
                keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)
                """
            )
            // Don't proceed with registration - keep old hotkey or leave as nil
            return
        }

        if let oldHotKey = popupCloseHotKey { scheduleDeallocation(oldHotKey) }
        popupCloseHotKey = nil

        let hotKey = HotKey(
            carbonKeyCode: combo.carbonKeyCode,
            carbonModifiers: combo.carbonModifiers
        )
        hotKey.keyDownHandler = handler
        popupCloseHotKey = hotKey
        logger.info(
            "Popup close hotkey registered: keyCode=\(combo.carbonKeyCode), mods=\(combo.carbonModifiers)"
        )
    }

    /// ポップアップ用ホットキーをすべて解除
    func unregisterPopupHotKeys() {
        popupCopyAndCloseHotKey = nil
        popupSaveToFileHotKey = nil
        popupCloseHotKey = nil
        logger.info("All popup hotkeys unregistered")
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
            },
            registerPopupCopyAndClose: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerPopupCopyAndClose(combo, handler: handler)
                }
            },
            registerPopupSaveToFile: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerPopupSaveToFile(combo, handler: handler)
                }
            },
            registerPopupClose: { combo, handler in
                await MainActor.run {
                    HotKeyManager.shared.registerPopupClose(combo, handler: handler)
                }
            },
            unregisterPopupHotKeys: {
                await MainActor.run {
                    HotKeyManager.shared.unregisterPopupHotKeys()
                }
            }
        )
    }
}
