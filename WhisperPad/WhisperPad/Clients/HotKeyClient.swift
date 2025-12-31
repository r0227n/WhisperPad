//
//  HotKeyClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

nonisolated(unsafe) private let clientLogger = Logger(
    subsystem: "com.whisperpad",
    category: "HotKeyClient"
)

/// ホットキー管理クライアント
///
/// グローバルホットキーの登録・解除を提供します。
/// グローバルホットキーを使用するには、アクセシビリティ権限が必要です。
struct HotKeyClient: Sendable {
    /// 設定画面を開くホットキーを登録
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerOpenSettings: @Sendable (@escaping @Sendable () -> Void) async -> Void

    /// 設定画面を開くホットキーを解除
    var unregisterOpenSettings: @Sendable () async -> Void

    /// アクセシビリティ権限をチェック
    /// - Returns: 権限がある場合は true
    var checkAccessibilityPermission: @Sendable () async -> Bool

    /// アクセシビリティ権限を要求（システム環境設定を開く）
    var requestAccessibilityPermission: @Sendable () async -> Void

    /// 録音トグルホットキーを登録 (⌥ Space)
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerRecordingToggle: @Sendable (@escaping @Sendable () -> Void) async -> Void

    /// 録音トグルホットキーを解除
    var unregisterRecordingToggle: @Sendable () async -> Void

    /// ペーストホットキーを登録 (⌘⇧V)
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerPaste: @Sendable (@escaping @Sendable () -> Void) async -> Void

    /// ペーストホットキーを解除
    var unregisterPaste: @Sendable () async -> Void

    /// 録音キャンセルホットキーを登録 (Escape)
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerCancel: @Sendable (@escaping @Sendable () -> Void) async -> Void

    /// 録音キャンセルホットキーを解除
    var unregisterCancel: @Sendable () async -> Void

    // MARK: - 動的キーコンボ対応

    /// 動的キーコンボで録音ホットキーを登録（Push-to-Talk対応）
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - keyDownHandler: キーが押されたときのハンドラー
    ///   - keyUpHandler: キーが離されたときのハンドラー（Push-to-Talk用）
    var registerRecordingWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// 動的キーコンボでペーストホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerPasteWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// 動的キーコンボで設定を開くホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerOpenSettingsWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// すべてのホットキーを解除
    var unregisterAll: @Sendable () async -> Void
}

// MARK: - HotKeyError

/// ホットキー関連のエラー型
enum HotKeyError: Error, Equatable, Sendable, LocalizedError {
    /// アクセシビリティ権限がない
    case accessibilityPermissionDenied

    /// ホットキーの登録に失敗
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            "グローバルホットキーを使用するにはアクセシビリティ権限が必要です。"
        case let .registrationFailed(message):
            "ホットキーの登録に失敗しました: \(message)"
        }
    }
}

// MARK: - TestDependencyKey

extension HotKeyClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            registerOpenSettings: { _ in
                clientLogger.debug("[PREVIEW] registerOpenSettings called")
            },
            unregisterOpenSettings: {
                clientLogger.debug("[PREVIEW] unregisterOpenSettings called")
            },
            checkAccessibilityPermission: {
                clientLogger.debug("[PREVIEW] checkAccessibilityPermission called")
                return true
            },
            requestAccessibilityPermission: {
                clientLogger.debug("[PREVIEW] requestAccessibilityPermission called")
            },
            registerRecordingToggle: { _ in
                clientLogger.debug("[PREVIEW] registerRecordingToggle called")
            },
            unregisterRecordingToggle: {
                clientLogger.debug("[PREVIEW] unregisterRecordingToggle called")
            },
            registerPaste: { _ in
                clientLogger.debug("[PREVIEW] registerPaste called")
            },
            unregisterPaste: {
                clientLogger.debug("[PREVIEW] unregisterPaste called")
            },
            registerCancel: { _ in
                clientLogger.debug("[PREVIEW] registerCancel called")
            },
            unregisterCancel: {
                clientLogger.debug("[PREVIEW] unregisterCancel called")
            },
            registerRecordingWithCombo: { _, _, _ in
                clientLogger.debug("[PREVIEW] registerRecordingWithCombo called")
            },
            registerPasteWithCombo: { _, _ in
                clientLogger.debug("[PREVIEW] registerPasteWithCombo called")
            },
            registerOpenSettingsWithCombo: { _, _ in
                clientLogger.debug("[PREVIEW] registerOpenSettingsWithCombo called")
            },
            unregisterAll: {
                clientLogger.debug("[PREVIEW] unregisterAll called")
            }
        )
    }

    static var testValue: Self {
        Self(
            registerOpenSettings: { _ in
                clientLogger.debug("[TEST] registerOpenSettings called")
            },
            unregisterOpenSettings: {
                clientLogger.debug("[TEST] unregisterOpenSettings called")
            },
            checkAccessibilityPermission: {
                clientLogger.debug("[TEST] checkAccessibilityPermission called")
                return true
            },
            requestAccessibilityPermission: {
                clientLogger.debug("[TEST] requestAccessibilityPermission called")
            },
            registerRecordingToggle: { _ in
                clientLogger.debug("[TEST] registerRecordingToggle called")
            },
            unregisterRecordingToggle: {
                clientLogger.debug("[TEST] unregisterRecordingToggle called")
            },
            registerPaste: { _ in
                clientLogger.debug("[TEST] registerPaste called")
            },
            unregisterPaste: {
                clientLogger.debug("[TEST] unregisterPaste called")
            },
            registerCancel: { _ in
                clientLogger.debug("[TEST] registerCancel called")
            },
            unregisterCancel: {
                clientLogger.debug("[TEST] unregisterCancel called")
            },
            registerRecordingWithCombo: { _, _, _ in
                clientLogger.debug("[TEST] registerRecordingWithCombo called")
            },
            registerPasteWithCombo: { _, _ in
                clientLogger.debug("[TEST] registerPasteWithCombo called")
            },
            registerOpenSettingsWithCombo: { _, _ in
                clientLogger.debug("[TEST] registerOpenSettingsWithCombo called")
            },
            unregisterAll: {
                clientLogger.debug("[TEST] unregisterAll called")
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var hotKeyClient: HotKeyClient {
        get { self[HotKeyClient.self] }
        set { self[HotKeyClient.self] = newValue }
    }
}
