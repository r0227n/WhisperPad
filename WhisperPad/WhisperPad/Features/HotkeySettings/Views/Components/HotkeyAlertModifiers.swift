//
//  HotkeyAlertModifiers.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ホットキー設定用のアラートモディファイアを提供するView拡張
///
/// 3つのアラート（システム競合、アプリ内重複、システム予約済み）を一括適用します。
/// HotkeySettingsTabで使用されます。
extension View {
    /// ホットキー競合アラートを適用（HotkeySettingsFeature用）
    ///
    /// - Parameter store: HotkeySettingsFeatureのStore
    /// - Returns: アラートが適用されたView
    func hotkeyConflictAlertsForHotkeySettings(
        store: StoreOf<HotkeySettingsFeature>
    ) -> some View {
        let appLocale = store.preferredLocale
        let conflictAlertView = hotkeyConflictAlert(store: store, appLocale: appLocale)
        let duplicateAlertView = conflictAlertView.hotkeyDuplicateAlert(store: store, appLocale: appLocale)
        return duplicateAlertView.hotkeySystemReservedAlert(store: store, appLocale: appLocale)
    }

    /// システム競合アラート
    private func hotkeyConflictAlert(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> some View {
        self.alert(
            appLocale.localized("hotkey.conflict_alert.title"),
            isPresented: Binding(
                get: { store.showHotkeyConflictAlert },
                set: { if !$0 { store.send(.dismissConflictAlert) } }
            )
        ) {
            Button(appLocale.localized("common.ok"), role: .cancel) {
                store.send(.dismissConflictAlert)
            }
        } message: {
            Text(conflictAlertMessage(store: store, appLocale: appLocale))
        }
    }

    private func conflictAlertMessage(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> String {
        guard let type = store.conflictingHotkeyType else {
            return appLocale.localized("hotkey.conflict_alert.message_generic")
        }
        let format = appLocale.localized("hotkey.conflict_alert.message")
        let typeName = appLocale.localized(String.LocalizationValue(type.localizationKey))
        return String(format: format, typeName)
    }

    /// アプリ内重複アラート
    private func hotkeyDuplicateAlert(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> some View {
        self.alert(
            appLocale.localized("hotkey.duplicate_alert.title"),
            isPresented: Binding(
                get: { store.showDuplicateHotkeyAlert },
                set: { if !$0 { store.send(.dismissDuplicateAlert) } }
            )
        ) {
            Button(appLocale.localized("common.ok"), role: .cancel) {
                store.send(.dismissDuplicateAlert)
            }
        } message: {
            Text(duplicateAlertMessage(store: store, appLocale: appLocale))
        }
    }

    private func duplicateAlertMessage(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> String {
        guard let targetType = store.conflictingHotkeyType,
              let duplicateType = store.duplicateWithHotkeyType else {
            return appLocale.localized("hotkey.duplicate_alert.message_generic")
        }
        let format = appLocale.localized("hotkey.duplicate_alert.message")
        let targetName = appLocale.localized(String.LocalizationValue(targetType.localizationKey))
        let duplicateName = appLocale.localized(String.LocalizationValue(duplicateType.localizationKey))
        return String(format: format, targetName, duplicateName)
    }

    /// システム予約済みアラート
    private func hotkeySystemReservedAlert(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> some View {
        self.alert(
            appLocale.localized("hotkey.system_reserved_alert.title"),
            isPresented: Binding(
                get: { store.showSystemReservedAlert },
                set: { if !$0 { store.send(.dismissSystemReservedAlert) } }
            )
        ) {
            Button(appLocale.localized("common.ok"), role: .cancel) {
                store.send(.dismissSystemReservedAlert)
            }
        } message: {
            Text(systemReservedAlertMessage(store: store, appLocale: appLocale))
        }
    }

    private func systemReservedAlertMessage(
        store: StoreOf<HotkeySettingsFeature>,
        appLocale: AppLocale
    ) -> String {
        guard let type = store.conflictingHotkeyType else {
            return appLocale.localized("hotkey.system_reserved_alert.message_generic")
        }
        let format = appLocale.localized("hotkey.system_reserved_alert.message")
        let typeName = appLocale.localized(String.LocalizationValue(type.localizationKey))
        return String(format: format, typeName)
    }
}
