//
//  GeneralSettingsFeature.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation

// MARK: - GeneralSettings Feature

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

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// 一般設定が変更された
            case generalSettingsChanged(GeneralSettings)
        }
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .updateGeneralSettings(general):
                state.general = general
                return .send(.delegate(.generalSettingsChanged(general)))

            case .fetchLanguages:
                let allLanguages = TranscriptionLanguage.allSupported
                return .send(.languagesResponse(allLanguages))

            case let .languagesResponse(languages):
                state.availableLanguages = languages
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
