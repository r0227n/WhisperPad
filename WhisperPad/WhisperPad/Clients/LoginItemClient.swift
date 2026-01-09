//
//  LoginItemClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation

/// Login Item管理クライアント
///
/// macOSのLogin Items（ログイン時自動起動）を管理します。
struct LoginItemClient: Sendable {
    /// Login Itemsに登録
    /// - Throws: 登録に失敗した場合
    var register: @Sendable () async throws -> Void

    /// Login Itemsから解除
    /// - Throws: 解除に失敗した場合
    var unregister: @Sendable () async throws -> Void

    /// 現在のLogin Items状態を取得
    /// - Returns: 登録されている場合true、そうでない場合false
    var status: @Sendable () async -> Bool
}

// MARK: - LoginItemError

/// Login Items操作のエラー型
enum LoginItemError: Error, Equatable, Sendable, LocalizedError {
    /// 登録に失敗
    case registrationFailed

    /// 解除に失敗
    case unregistrationFailed

    /// 状態確認に失敗
    case statusCheckFailed

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            "Login Itemsへの登録に失敗しました"
        case .unregistrationFailed:
            "Login Itemsからの解除に失敗しました"
        case .statusCheckFailed:
            "Login Items状態の確認に失敗しました"
        }
    }
}

// MARK: - TestDependencyKey

extension LoginItemClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            register: {},
            unregister: {},
            status: { false }
        )
    }

    static var testValue: Self {
        Self(
            register: { unimplemented("LoginItemClient.register", placeholder: ()) },
            unregister: { unimplemented("LoginItemClient.unregister", placeholder: ()) },
            status: { unimplemented("LoginItemClient.status", placeholder: false) }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var loginItemClient: LoginItemClient {
        get { self[LoginItemClient.self] }
        set { self[LoginItemClient.self] = newValue }
    }
}
