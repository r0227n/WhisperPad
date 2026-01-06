//
//  HotkeySettingsFeature.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation

// MARK: - HotkeySettings Feature

/// ホットキー設定機能の TCA Reducer
///
/// グローバルショートカットの設定、競合検出、検証を管理します。
@Reducer
struct HotkeySettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// ホットキー設定
        var hotKey: HotKeySettings

        /// ホットキー録音中のタイプ（nil = 録音なし）
        var recordingHotkeyType: HotkeyType?

        /// ホットキー競合警告メッセージ
        var hotkeyConflict: String?

        /// システム競合アラートの表示フラグ
        var showHotkeyConflictAlert = false

        /// 競合しているhotkeyタイプ（アラート表示用）
        var conflictingHotkeyType: HotkeyType?

        /// 競合前の設定値（ロールバック用）
        var previousHotKeySettings: HotKeySettings?

        /// 重複検出アラートの表示フラグ
        var showDuplicateHotkeyAlert = false

        /// 重複している相手のホットキータイプ
        var duplicateWithHotkeyType: HotkeyType?

        /// システム予約済みショートカットアラートの表示フラグ
        var showSystemReservedAlert = false

        /// 選択中のショートカット（ホットキー設定タブ用）
        var selectedShortcut: HotkeyType?

        /// メニューバーアイコン設定（表示用）
        var menuBarIconSettings: MenuBarIconSettings

        /// ユーザーの優先ロケール（アラートメッセージ用）
        var preferredLocale: AppLocale

        init(
            hotKey: HotKeySettings = .default,
            recordingHotkeyType: HotkeyType? = nil,
            hotkeyConflict: String? = nil,
            showHotkeyConflictAlert: Bool = false,
            conflictingHotkeyType: HotkeyType? = nil,
            previousHotKeySettings: HotKeySettings? = nil,
            showDuplicateHotkeyAlert: Bool = false,
            duplicateWithHotkeyType: HotkeyType? = nil,
            showSystemReservedAlert: Bool = false,
            selectedShortcut: HotkeyType? = nil,
            menuBarIconSettings: MenuBarIconSettings = .default,
            preferredLocale: AppLocale = .system
        ) {
            self.hotKey = hotKey
            self.recordingHotkeyType = recordingHotkeyType
            self.hotkeyConflict = hotkeyConflict
            self.showHotkeyConflictAlert = showHotkeyConflictAlert
            self.conflictingHotkeyType = conflictingHotkeyType
            self.previousHotKeySettings = previousHotKeySettings
            self.showDuplicateHotkeyAlert = showDuplicateHotkeyAlert
            self.duplicateWithHotkeyType = duplicateWithHotkeyType
            self.showSystemReservedAlert = showSystemReservedAlert
            self.selectedShortcut = selectedShortcut
            self.menuBarIconSettings = menuBarIconSettings
            self.preferredLocale = preferredLocale
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Settings Updates

        /// ホットキー設定を更新
        case updateHotKeySettings(HotKeySettings)

        // MARK: - Hotkey Recording

        /// ホットキー録音を開始
        case startRecordingHotkey(HotkeyType)
        /// ホットキー録音を停止
        case stopRecordingHotkey
        /// ショートカットを選択
        case selectShortcut(HotkeyType?)

        // MARK: - Hotkey Validation

        /// ホットキー競合をチェック
        case checkHotkeyConflict
        /// hotkey更新前に検証を実行
        case validateAndUpdateHotkey(HotkeyType, HotKeySettings.KeyComboSettings)
        /// システム競合が検出された
        case hotkeyConflictDetected(HotkeyType)
        /// 競合アラートを閉じた
        case dismissConflictAlert
        /// アプリ内重複が検出された
        case duplicateHotkeyDetected(HotkeyType, duplicateWith: HotkeyType)
        /// 重複アラートを閉じた
        case dismissDuplicateAlert
        /// システム予約済みショートカットが検出された
        case systemReservedShortcutDetected(HotkeyType)
        /// システム予約済みアラートを閉じた
        case dismissSystemReservedAlert

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// ホットキー設定が変更された
            case hotKeySettingsChanged(HotKeySettings)
        }
    }

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .updateHotKeySettings(hotKey):
                state.hotKey = hotKey
                return .merge(
                    .send(.delegate(.hotKeySettingsChanged(hotKey))),
                    .send(.checkHotkeyConflict)
                )

            case let .startRecordingHotkey(type):
                state.recordingHotkeyType = type
                return .none

            case .stopRecordingHotkey:
                state.recordingHotkeyType = nil
                return .none

            case let .selectShortcut(shortcut):
                state.selectedShortcut = shortcut
                return .none

            case .checkHotkeyConflict:
                let hotKey = state.hotKey
                let combos: [(String, HotKeySettings.KeyComboSettings)] = [
                    (HotkeyType.recording.displayName, hotKey.recordingHotKey),
                    (HotkeyType.cancel.displayName, hotKey.cancelHotKey),
                    (HotkeyType.recordingPause.displayName, hotKey.recordingPauseHotKey)
                ]

                var conflicts: [String] = []
                for index in 0 ..< combos.count {
                    for otherIndex in (index + 1) ..< combos.count {
                        let (name1, combo1) = combos[index]
                        let (name2, combo2) = combos[otherIndex]
                        if combo1.carbonKeyCode == combo2.carbonKeyCode,
                           combo1.carbonModifiers == combo2.carbonModifiers {
                            conflicts.append(
                                name1 + String(localized: "hotkey.conflict.and", comment: " and ") + name2
                            )
                        }
                    }
                }

                if conflicts.isEmpty {
                    state.hotkeyConflict = nil
                } else {
                    state.hotkeyConflict = String(
                        localized: "hotkey.conflict.prefix",
                        comment: "Conflict: "
                    ) + conflicts.joined(separator: ", ")
                }
                return .none

            case let .validateAndUpdateHotkey(type, newCombo):
                // 設定を更新する前に現在の値を保存（ロールバック用）
                state.previousHotKeySettings = state.hotKey

                // アプリ内重複チェック（デフォルト設定との重複は許可）
                if let duplicateType = HotKeyValidator.findDuplicate(
                    carbonKeyCode: newCombo.carbonKeyCode,
                    carbonModifiers: newCombo.carbonModifiers,
                    currentType: type,
                    in: state.hotKey
                ) {
                    // 重複検出 → アラート表示
                    return .send(.duplicateHotkeyDetected(type, duplicateWith: duplicateType))
                }

                // 仮更新（検証のため）
                updateHotkeySetting(&state.hotKey, type: type, combo: newCombo)

                // Carbon APIでシステム競合を検証
                return .run { [settings = state.hotKey] send in
                    let validation = HotKeyValidator.canRegister(
                        carbonKeyCode: newCombo.carbonKeyCode,
                        carbonModifiers: newCombo.carbonModifiers
                    )

                    switch validation {
                    case .success:
                        // 競合なし → 更新を確定
                        await send(.updateHotKeySettings(settings))
                    case .failure(.reservedSystemShortcut):
                        // システム予約済みショートカット → アラート表示
                        await send(.systemReservedShortcutDetected(type))
                    case .failure:
                        // システム競合あり → アラート表示
                        await send(.hotkeyConflictDetected(type))
                    }
                }

            case let .hotkeyConflictDetected(type):
                // 競合が検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = type
                state.showHotkeyConflictAlert = true

                return .none

            case .dismissConflictAlert:
                state.showHotkeyConflictAlert = false
                state.conflictingHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case let .duplicateHotkeyDetected(targetType, duplicateType):
                // 重複が検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = targetType
                state.duplicateWithHotkeyType = duplicateType
                state.showDuplicateHotkeyAlert = true

                return .none

            case .dismissDuplicateAlert:
                state.showDuplicateHotkeyAlert = false
                state.conflictingHotkeyType = nil
                state.duplicateWithHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case let .systemReservedShortcutDetected(type):
                // システム予約済みショートカットが検出されたら、設定を元に戻す
                if let previous = state.previousHotKeySettings {
                    state.hotKey = previous
                }

                // アラート表示フラグを立てる
                state.conflictingHotkeyType = type
                state.showSystemReservedAlert = true

                return .none

            case .dismissSystemReservedAlert:
                state.showSystemReservedAlert = false
                state.conflictingHotkeyType = nil
                state.previousHotKeySettings = nil

                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Functions

/// HotKeySettingsの特定のhotkeyタイプを更新するヘルパー関数
private func updateHotkeySetting(
    _ hotKey: inout HotKeySettings,
    type: HotkeyType,
    combo: HotKeySettings.KeyComboSettings
) {
    switch type {
    case .recording:
        hotKey.recordingHotKey = combo
    case .cancel:
        hotKey.cancelHotKey = combo
    case .recordingPause:
        hotKey.recordingPauseHotKey = combo
    }
}

// MARK: - Binding Helpers

extension StoreOf<HotkeySettingsFeature> {
    /// HotKey Settings 用のバインディングを作成
    func bindingForHotKey<T: Equatable>(
        keyPath: WritableKeyPath<HotKeySettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.hotKey[keyPath: keyPath] },
            set: { newValue in
                var hotKey = self.hotKey
                hotKey[keyPath: keyPath] = newValue
                self.send(.updateHotKeySettings(hotKey))
            }
        )
    }
}
