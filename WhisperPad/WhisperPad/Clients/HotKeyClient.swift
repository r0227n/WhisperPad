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

    /// 録音キャンセルホットキーを登録 (Escape)
    /// - Parameter handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerCancel: @Sendable (@escaping @Sendable () -> Void) async -> Void

    /// 録音キャンセルホットキーを解除
    var unregisterCancel: @Sendable () async -> Void

    // MARK: - 動的キーコンボ対応

    /// 動的キーコンボで録音ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerRecordingWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// 動的キーコンボでキャンセルホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerCancelWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// すべてのホットキーを解除
    var unregisterAll: @Sendable () async -> Void

    /// 動的キーコンボで録音一時停止ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerRecordingPauseWithCombo: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    // MARK: - ポップアップ用ホットキー

    /// ポップアップ: コピーして閉じるホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerPopupCopyAndClose: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// ポップアップ: ファイル保存ホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerPopupSaveToFile: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// ポップアップ: 閉じるホットキーを登録
    /// - Parameters:
    ///   - combo: キーコンボ設定
    ///   - handler: ホットキーが押されたときに呼ばれるハンドラー
    var registerPopupClose: @Sendable (
        HotKeySettings.KeyComboSettings,
        @escaping @Sendable () -> Void
    ) async -> Void

    /// ポップアップ用ホットキーをすべて解除
    var unregisterPopupHotKeys: @Sendable () async -> Void
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
            registerCancel: { _ in
                clientLogger.debug("[PREVIEW] registerCancel called")
            },
            unregisterCancel: {
                clientLogger.debug("[PREVIEW] unregisterCancel called")
            },
            registerRecordingWithCombo: { _, _ in
                clientLogger.debug("[PREVIEW] registerRecordingWithCombo called")
            },
            registerCancelWithCombo: { _, _ in
                clientLogger.debug("[PREVIEW] registerCancelWithCombo called")
            },
            unregisterAll: {
                clientLogger.debug("[PREVIEW] unregisterAll called")
            },
            registerRecordingPauseWithCombo: { _, _ in
                clientLogger.debug("[PREVIEW] registerRecordingPauseWithCombo called")
            },
            registerPopupCopyAndClose: { _, _ in
                clientLogger.debug("[PREVIEW] registerPopupCopyAndClose called")
            },
            registerPopupSaveToFile: { _, _ in
                clientLogger.debug("[PREVIEW] registerPopupSaveToFile called")
            },
            registerPopupClose: { _, _ in
                clientLogger.debug("[PREVIEW] registerPopupClose called")
            },
            unregisterPopupHotKeys: {
                clientLogger.debug("[PREVIEW] unregisterPopupHotKeys called")
            }
        )
    }

    static var testValue: Self {
        Self(
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
            registerCancel: { _ in
                clientLogger.debug("[TEST] registerCancel called")
            },
            unregisterCancel: {
                clientLogger.debug("[TEST] unregisterCancel called")
            },
            registerRecordingWithCombo: { _, _ in
                clientLogger.debug("[TEST] registerRecordingWithCombo called")
            },
            registerCancelWithCombo: { _, _ in
                clientLogger.debug("[TEST] registerCancelWithCombo called")
            },
            unregisterAll: {
                clientLogger.debug("[TEST] unregisterAll called")
            },
            registerRecordingPauseWithCombo: { _, _ in
                clientLogger.debug("[TEST] registerRecordingPauseWithCombo called")
            },
            registerPopupCopyAndClose: { _, _ in
                clientLogger.debug("[TEST] registerPopupCopyAndClose called")
            },
            registerPopupSaveToFile: { _, _ in
                clientLogger.debug("[TEST] registerPopupSaveToFile called")
            },
            registerPopupClose: { _, _ in
                clientLogger.debug("[TEST] registerPopupClose called")
            },
            unregisterPopupHotKeys: {
                clientLogger.debug("[TEST] unregisterPopupHotKeys called")
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
