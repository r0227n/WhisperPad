//
//  OutputClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "OutputClient")

/// 出力クライアント
///
/// クリップボードへのコピー、ファイル出力、通知表示、完了音再生を提供します。
struct OutputClient: Sendable {
    /// テキストをクリップボードにコピー
    /// - Parameter text: コピーするテキスト
    /// - Returns: 成功した場合は true
    var copyToClipboard: @Sendable (_ text: String) async -> Bool

    /// テキストをファイルに保存
    /// - Parameters:
    ///   - text: 保存するテキスト
    ///   - settings: ファイル出力設定
    /// - Returns: 保存されたファイルの URL
    /// - Throws: ファイル保存に失敗した場合は OutputError
    var saveToFile: @Sendable (_ text: String, _ settings: FileOutputSettings) async throws -> URL

    /// 通知を表示
    /// - Parameters:
    ///   - title: 通知タイトル
    ///   - body: 通知本文
    var showNotification: @Sendable (_ title: String, _ body: String) async -> Void

    /// 完了音を再生
    var playCompletionSound: @Sendable () async -> Void

    /// 通知権限を要求
    /// - Returns: 権限が許可された場合は true
    var requestNotificationPermission: @Sendable () async -> Bool
}

// MARK: - OutputError

/// 出力関連のエラー型
enum OutputError: Error, Equatable, Sendable, LocalizedError {
    /// クリップボードへの書き込みに失敗
    case clipboardWriteFailed

    /// ファイルへの書き込みに失敗
    case fileWriteFailed(String)

    /// ディレクトリの作成に失敗
    case directoryCreationFailed(String)

    /// 通知の表示に失敗
    case notificationFailed(String)

    /// 通知権限が拒否された
    case notificationPermissionDenied

    var errorDescription: String? {
        switch self {
        case .clipboardWriteFailed:
            "クリップボードへの書き込みに失敗しました。"
        case let .fileWriteFailed(message):
            "ファイルへの書き込みに失敗しました: \(message)"
        case let .directoryCreationFailed(message):
            "ディレクトリの作成に失敗しました: \(message)"
        case let .notificationFailed(message):
            "通知の表示に失敗しました: \(message)"
        case .notificationPermissionDenied:
            "通知権限が許可されていません。"
        }
    }
}

// MARK: - TestDependencyKey

extension OutputClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            copyToClipboard: { _ in
                clientLogger.debug("[DEBUG] previewValue.copyToClipboard called!")
                return true
            },
            saveToFile: { _, settings in
                clientLogger.debug("[DEBUG] previewValue.saveToFile called!")
                return settings.generateFilePath()
            },
            showNotification: { _, _ in
                clientLogger.debug("[DEBUG] previewValue.showNotification called!")
            },
            playCompletionSound: {
                clientLogger.debug("[DEBUG] previewValue.playCompletionSound called!")
            },
            requestNotificationPermission: {
                clientLogger.debug("[DEBUG] previewValue.requestNotificationPermission called!")
                return true
            }
        )
    }

    static var testValue: Self {
        Self(
            copyToClipboard: { _ in
                clientLogger.debug("[DEBUG] testValue.copyToClipboard called!")
                return true
            },
            saveToFile: { _, settings in
                clientLogger.debug("[DEBUG] testValue.saveToFile called!")
                return settings.generateFilePath()
            },
            showNotification: { _, _ in
                clientLogger.debug("[DEBUG] testValue.showNotification called!")
            },
            playCompletionSound: {
                clientLogger.debug("[DEBUG] testValue.playCompletionSound called!")
            },
            requestNotificationPermission: {
                clientLogger.debug("[DEBUG] testValue.requestNotificationPermission called!")
                return true
            }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var outputClient: OutputClient {
        get { self[OutputClient.self] }
        set { self[OutputClient.self] = newValue }
    }
}
