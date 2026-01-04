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
    /// ホットキー競合アラートを適用
    ///
    /// - Parameter store: SettingsFeatureのStore
    /// - Returns: アラートが適用されたView
    // swiftlint:disable:next function_body_length
    func hotkeyConflictAlerts(
        store: StoreOf<SettingsFeature>
    ) -> some View {
        self
            .alert(
                Text("hotkey.conflict_alert.title"),
                isPresented: Binding(
                    get: { store.showHotkeyConflictAlert },
                    set: { if !$0 { store.send(.dismissConflictAlert) } }
                )
            ) {
                Button("common.ok", role: .cancel) {
                    store.send(.dismissConflictAlert)
                }
            } message: {
                if let type = store.conflictingHotkeyType {
                    let userLocale = store.settings.general.preferredLocale.locale
                    let languageCode = userLocale.language.languageCode?.identifier ?? "en"
                    let format = Bundle.main.localizedString(
                        forKey: "hotkey.conflict_alert.message",
                        preferredLanguage: languageCode
                    )
                    let typeName = Bundle.main.localizedString(
                        forKey: type.localizedKeyString,
                        preferredLanguage: languageCode
                    )
                    Text(verbatim: String(format: format, typeName))
                } else {
                    Text("hotkey.conflict_alert.message_generic")
                }
            }
            .alert(
                Text("hotkey.duplicate_alert.title"),
                isPresented: Binding(
                    get: { store.showDuplicateHotkeyAlert },
                    set: { if !$0 { store.send(.dismissDuplicateAlert) } }
                )
            ) {
                Button("common.ok", role: .cancel) {
                    store.send(.dismissDuplicateAlert)
                }
            } message: {
                if let targetType = store.conflictingHotkeyType,
                   let duplicateType = store.duplicateWithHotkeyType {
                    let userLocale = store.settings.general.preferredLocale.locale
                    let languageCode = userLocale.language.languageCode?.identifier ?? "en"
                    let format = Bundle.main.localizedString(
                        forKey: "hotkey.duplicate_alert.message",
                        preferredLanguage: languageCode
                    )
                    let targetName = Bundle.main.localizedString(
                        forKey: targetType.localizedKeyString,
                        preferredLanguage: languageCode
                    )
                    let duplicateName = Bundle.main.localizedString(
                        forKey: duplicateType.localizedKeyString,
                        preferredLanguage: languageCode
                    )
                    Text(verbatim: String(format: format, targetName, duplicateName))
                } else {
                    Text("hotkey.duplicate_alert.message_generic")
                }
            }
            .alert(
                Text("hotkey.system_reserved_alert.title"),
                isPresented: Binding(
                    get: { store.showSystemReservedAlert },
                    set: { if !$0 { store.send(.dismissSystemReservedAlert) } }
                )
            ) {
                Button("common.ok", role: .cancel) {
                    store.send(.dismissSystemReservedAlert)
                }
            } message: {
                if let type = store.conflictingHotkeyType {
                    let userLocale = store.settings.general.preferredLocale.locale
                    let languageCode = userLocale.language.languageCode?.identifier ?? "en"
                    let format = Bundle.main.localizedString(
                        forKey: "hotkey.system_reserved_alert.message",
                        preferredLanguage: languageCode
                    )
                    let typeName = Bundle.main.localizedString(
                        forKey: type.localizedKeyString,
                        preferredLanguage: languageCode
                    )
                    Text(verbatim: String(format: format, typeName))
                } else {
                    Text("hotkey.system_reserved_alert.message_generic")
                }
            }
    }
}

