//
//  HotKeyClientLive.swift
//  WhisperPad
//

import AppKit
import ApplicationServices
import Dependencies
import HotKey
import OSLog

private nonisolated(unsafe) let logger = Logger(
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

    private init() {}

    /// 設定画面を開くホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    func registerOpenSettings(handler: @escaping () -> Void) {
        // 既存のホットキーを解除
        openSettingsHotKey = nil

        // 新しいホットキーを登録 (Command + Shift + ,)
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
                // AXIsProcessTrusted() はアクセシビリティ権限をチェック
                let trusted = AXIsProcessTrusted()
                logger.info("Accessibility permission: \(trusted ? "granted" : "denied")")
                return trusted
            },
            requestAccessibilityPermission: {
                // アクセシビリティ権限を要求するダイアログを表示
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
                logger.info("Accessibility permission requested, current status: \(trusted)")
            }
        )
    }
}
