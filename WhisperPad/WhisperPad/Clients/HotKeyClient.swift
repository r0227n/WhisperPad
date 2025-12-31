//
//  HotKeyClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private nonisolated(unsafe) let clientLogger = Logger(
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
