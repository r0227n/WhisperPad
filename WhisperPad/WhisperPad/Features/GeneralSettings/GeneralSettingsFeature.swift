//
//  GeneralSettingsFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog
import SwiftUI

// MARK: - GeneralSettings Feature

private let featureLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.whisperpad",
    category: "GeneralSettingsFeature"
)

/// 一般設定機能の TCA Reducer
///
/// 言語設定、起動設定、通知設定、パフォーマンス設定を管理します。
@Reducer
struct GeneralSettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 一般設定
        var general: GeneralSettings

        /// 利用可能な文字起こし言語一覧
        var availableLanguages: [TranscriptionLanguage] = []

        init(
            general: GeneralSettings = .default,
            availableLanguages: [TranscriptionLanguage] = []
        ) {
            self.general = general
            self.availableLanguages = availableLanguages
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Settings Updates

        /// 一般設定を更新
        case updateGeneralSettings(GeneralSettings)

        // MARK: - Languages

        /// 利用可能な言語を取得
        case fetchLanguages
        /// 言語一覧取得完了
        case languagesResponse([TranscriptionLanguage])

        // MARK: - Login Items

        /// Login Items状態を同期
        case syncLoginItemStatus
        /// Login Items状態を受信
        case loginItemStatusReceived(Bool)
        /// Login Items登録/解除結果
        case loginItemRegistrationResult(Result<Void, Error>)

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// 一般設定が変更された
            case generalSettingsChanged(GeneralSettings)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.loginItemClient) var loginItemClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .updateGeneralSettings(general):
                let oldValue = state.general.launchAtLogin
                let newValue = general.launchAtLogin
                state.general = general

                // launchAtLoginが変更された場合、Login Itemsを更新
                if oldValue != newValue {
                    return .run { send in
                        do {
                            if newValue {
                                try await loginItemClient.register()
                            } else {
                                try await loginItemClient.unregister()
                            }
                            await send(.loginItemRegistrationResult(.success(())))
                        } catch {
                            await send(.loginItemRegistrationResult(.failure(error)))
                        }
                        // 設定変更を通知
                        await send(.delegate(.generalSettingsChanged(general)))
                    }
                }

                return .send(.delegate(.generalSettingsChanged(general)))

            case .fetchLanguages:
                let allLanguages = TranscriptionLanguage.allSupported
                return .send(.languagesResponse(allLanguages))

            case let .languagesResponse(languages):
                state.availableLanguages = languages
                return .none

            case .syncLoginItemStatus:
                return .run { send in
                    let isEnabled = await loginItemClient.status()
                    await send(.loginItemStatusReceived(isEnabled))
                }

            case let .loginItemStatusReceived(isEnabled):
                // Login Itemsの実際の状態とUserDefaultsの設定を同期
                if state.general.launchAtLogin != isEnabled {
                    var general = state.general
                    general.launchAtLogin = isEnabled
                    state.general = general
                    return .send(.delegate(.generalSettingsChanged(general)))
                }
                return .none

            case let .loginItemRegistrationResult(.failure(error)):
                // エラーハンドリング: ログ出力のみ (ユーザーへの通知は不要)
                // システム設定で手動変更可能なため、失敗は許容
                featureLogger.error("Login item registration failed: \(error.localizedDescription)")
                return .none

            case .loginItemRegistrationResult(.success):
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Binding Helpers

extension StoreOf<GeneralSettingsFeature> {
    /// General Settings 用のバインディングを作成
    func bindingForGeneral<T: Equatable>(
        keyPath: WritableKeyPath<GeneralSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.general[keyPath: keyPath] },
            set: { newValue in
                var general = self.general
                general[keyPath: keyPath] = newValue
                self.send(.updateGeneralSettings(general))
            }
        )
    }
}
