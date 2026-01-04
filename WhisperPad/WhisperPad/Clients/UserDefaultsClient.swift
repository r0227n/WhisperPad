//
//  UserDefaultsClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "UserDefaultsClient")

/// 設定永続化クライアント
///
/// アプリケーション設定の保存・読み込みを提供します。
struct UserDefaultsClient: Sendable {
    /// 設定を読み込み
    /// - Returns: 保存されている設定、または未設定の場合はデフォルト値
    var loadSettings: @Sendable () async -> AppSettings

    /// 設定を保存
    /// - Parameter settings: 保存する設定
    var saveSettings: @Sendable (AppSettings) async throws -> Void

    /// Security-Scoped Bookmark を保存
    /// - Parameter bookmarkData: Bookmark データ
    var saveStorageBookmark: @Sendable (Data) async -> Void

    /// Security-Scoped Bookmark を読み込み
    /// - Returns: 保存されている Bookmark データ（存在しない場合は nil）
    var loadStorageBookmark: @Sendable () async -> Data?

    /// Bookmark から URL を解決
    /// - Parameter bookmarkData: Bookmark データ
    /// - Returns: 解決された URL（失敗した場合は nil）
    var resolveBookmark: @Sendable (Data) async -> URL?

    /// URL から Security-Scoped Bookmark を作成
    /// - Parameter url: Bookmark を作成する URL
    /// - Returns: 作成された Bookmark データ
    var createBookmark: @Sendable (URL) async throws -> Data

    /// デフォルトモデル名を読み込み
    /// - Returns: 保存されているモデル名（未設定の場合は nil）
    var loadDefaultModel: @Sendable () async -> String?

    /// デフォルトモデル名を保存
    /// - Parameter modelName: 保存するモデル名（nil の場合は削除）
    var saveDefaultModel: @Sendable (String?) async -> Void
}

// MARK: - UserDefaultsError

/// 設定保存関連のエラー型
enum UserDefaultsError: Error, Equatable, Sendable, LocalizedError {
    /// 設定のエンコードに失敗
    case encodingFailed(String)

    /// 設定のデコードに失敗
    case decodingFailed(String)

    /// Bookmark の作成に失敗
    case bookmarkCreationFailed(String)

    /// Bookmark の解決に失敗
    case bookmarkResolutionFailed(String)

    var errorDescription: String? {
        switch self {
        case let .encodingFailed(message):
            "設定の保存に失敗しました: \(message)"
        case let .decodingFailed(message):
            "設定の読み込みに失敗しました: \(message)"
        case let .bookmarkCreationFailed(message):
            "ブックマークの作成に失敗しました: \(message)"
        case let .bookmarkResolutionFailed(message):
            "ブックマークの解決に失敗しました: \(message)"
        }
    }
}

// MARK: - TestDependencyKey

extension UserDefaultsClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            loadSettings: {
                clientLogger.debug("[PREVIEW] loadSettings called")
                return .default
            },
            saveSettings: { _ in
                clientLogger.debug("[PREVIEW] saveSettings called")
            },
            saveStorageBookmark: { _ in
                clientLogger.debug("[PREVIEW] saveStorageBookmark called")
            },
            loadStorageBookmark: {
                clientLogger.debug("[PREVIEW] loadStorageBookmark called")
                return nil
            },
            resolveBookmark: { _ in
                clientLogger.debug("[PREVIEW] resolveBookmark called")
                return nil
            },
            createBookmark: { url in
                clientLogger.debug("[PREVIEW] createBookmark called for \(url.path)")
                return Data()
            },
            loadDefaultModel: {
                clientLogger.debug("[PREVIEW] loadDefaultModel called")
                return nil
            },
            saveDefaultModel: { modelName in
                clientLogger.debug("[PREVIEW] saveDefaultModel called with \(modelName ?? "nil")")
            }
        )
    }

    static var testValue: Self {
        Self(
            loadSettings: {
                clientLogger.debug("[TEST] loadSettings called")
                return .default
            },
            saveSettings: { _ in
                clientLogger.debug("[TEST] saveSettings called")
            },
            saveStorageBookmark: { _ in
                clientLogger.debug("[TEST] saveStorageBookmark called")
            },
            loadStorageBookmark: {
                clientLogger.debug("[TEST] loadStorageBookmark called")
                return nil
            },
            resolveBookmark: { _ in
                clientLogger.debug("[TEST] resolveBookmark called")
                return nil
            },
            createBookmark: { url in
                clientLogger.debug("[TEST] createBookmark called for \(url.path)")
                return Data()
            },
            loadDefaultModel: {
                clientLogger.debug("[TEST] loadDefaultModel called")
                return nil
            },
            saveDefaultModel: { modelName in
                clientLogger.debug("[TEST] saveDefaultModel called with \(modelName ?? "nil")")
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
