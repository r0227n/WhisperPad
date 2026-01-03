//
//  WhisperKitClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "WhisperKitClient")

/// WhisperKit 初期化管理クライアント
///
/// アプリ起動時の WhisperKit 初期化と状態管理を提供します。
/// WhisperKitManager を TCA の Dependency として利用可能にします。
struct WhisperKitClient: Sendable {
    /// WhisperKit を初期化
    /// - Parameter modelName: 使用するモデル名（nil の場合は推奨モデルを使用）
    var initialize: @Sendable (_ modelName: String?) async throws -> Void

    /// WhisperKit が使用可能かどうか
    var isReady: @Sendable () async -> Bool

    /// 現在の初期化状態を取得
    var getState: @Sendable () async -> WhisperKitManager.WhisperKitState

    /// 現在読み込まれているモデル名を取得
    var loadedModelName: @Sendable () async -> String?

    /// リソースを解放
    var unload: @Sendable () async -> Void

    /// アイドルタイムアウト設定を更新
    var configureIdleTimeout: @Sendable (_ enabled: Bool, _ minutes: Int) async -> Void
}

// MARK: - DependencyKey

extension WhisperKitClient: DependencyKey {
    static var liveValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("liveValue.initialize called with \(modelName ?? "nil")")
                try await WhisperKitManager.shared.initialize(modelName: modelName)
            },
            isReady: {
                await WhisperKitManager.shared.isReady
            },
            getState: {
                await WhisperKitManager.shared.state
            },
            loadedModelName: {
                await WhisperKitManager.shared.loadedModelName
            },
            unload: {
                clientLogger.debug("liveValue.unload called")
                await WhisperKitManager.shared.unload()
            },
            configureIdleTimeout: { enabled, minutes in
                clientLogger.debug("liveValue.configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
                await WhisperKitManager.shared.configureIdleTimeout(enabled: enabled, minutes: minutes)
            }
        )
    }
}

// MARK: - TestDependencyKey

extension WhisperKitClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[PREVIEW] initialize called with \(modelName ?? "nil")")
            },
            isReady: {
                true
            },
            getState: {
                .ready
            },
            loadedModelName: {
                "openai_whisper-small"
            },
            unload: {
                clientLogger.debug("[PREVIEW] unload called")
            },
            configureIdleTimeout: { enabled, minutes in
                clientLogger.debug("[PREVIEW] configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
            }
        )
    }

    static var testValue: Self {
        Self(
            initialize: { modelName in
                clientLogger.debug("[TEST] initialize called with \(modelName ?? "nil")")
            },
            isReady: {
                true
            },
            getState: {
                .ready
            },
            loadedModelName: {
                "openai_whisper-tiny"
            },
            unload: {
                clientLogger.debug("[TEST] unload called")
            },
            configureIdleTimeout: { enabled, minutes in
                clientLogger.debug("[TEST] configureIdleTimeout called: enabled=\(enabled), minutes=\(minutes)")
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var whisperKitClient: WhisperKitClient {
        get { self[WhisperKitClient.self] }
        set { self[WhisperKitClient.self] = newValue }
    }
}
