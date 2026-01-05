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
