//
//  IconSettingsFeature.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - IconSettings Feature

/// アイコン設定機能の TCA Reducer
///
/// メニューバーアイコンの設定を管理します。
/// 状態別のアイコン選択、色設定を提供します。
@Reducer
struct IconSettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// メニューバーアイコン設定
        var iconSettings: MenuBarIconSettings

        /// 選択中の状態
        var selectedStatus: IconConfigStatus = .idle

        /// ユーザーの優先ロケール（表示用）
        var preferredLocale: AppLocale

        init(
            iconSettings: MenuBarIconSettings = .default,
            selectedStatus: IconConfigStatus = .idle,
            preferredLocale: AppLocale = .system
        ) {
            self.iconSettings = iconSettings
            self.selectedStatus = selectedStatus
            self.preferredLocale = preferredLocale
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Status Selection

        /// 状態を選択
        case selectStatus(IconConfigStatus)

        // MARK: - Icon Config Updates

        /// アイコン設定を更新
        case updateIconConfig(IconConfigStatus, StatusIconConfig)
        /// 特定の状態のアイコン設定をデフォルトにリセット
        case resetIconSetting(IconConfigStatus)
        /// 全てのアイコン設定をデフォルトにリセット
        case resetAllIconSettings

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// アイコン設定が変更された
            case iconSettingsChanged(MenuBarIconSettings)
        }
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectStatus(status):
                state.selectedStatus = status
                return .none

            case let .updateIconConfig(status, config):
                state.iconSettings.setConfig(config, for: status)
                return .send(.delegate(.iconSettingsChanged(state.iconSettings)))

            case let .resetIconSetting(status):
                let defaultConfig = MenuBarIconSettings.default.config(for: status)
                state.iconSettings.setConfig(defaultConfig, for: status)
                return .send(.delegate(.iconSettingsChanged(state.iconSettings)))

            case .resetAllIconSettings:
                state.iconSettings = .default
                return .send(.delegate(.iconSettingsChanged(state.iconSettings)))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Binding Helpers

extension StoreOf<IconSettingsFeature> {
    /// 指定された状態のアイコン設定のバインディングを作成
    func bindingForIconConfig(
        status: IconConfigStatus
    ) -> Binding<StatusIconConfig> {
        Binding(
            get: { self.iconSettings.config(for: status) },
            set: { newConfig in
                self.send(.updateIconConfig(status, newConfig))
            }
        )
    }
}
