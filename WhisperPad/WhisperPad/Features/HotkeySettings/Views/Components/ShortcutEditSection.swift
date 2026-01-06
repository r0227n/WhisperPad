//
//  ShortcutEditSection.swift
//  WhisperPad
//

import SwiftUI

/// ショートカット編集セクション
///
/// ShortcutKeyButton + 競合警告 + ヘルプテキストを提供します。
/// HotkeySettingsTabで使用されます。
struct ShortcutEditSection: View {
    /// キーコンボのバインディング
    @Binding var keyCombo: HotKeySettings.KeyComboSettings
    /// デフォルトのキーコンボ
    let defaultKeyCombo: HotKeySettings.KeyComboSettings
    /// ホットキータイプ
    let hotkeyType: HotkeyType
    /// 録音中かどうか
    let isRecording: Bool
    /// 競合メッセージ（オプショナル）
    let hotkeyConflict: String?
    /// 録音開始アクション
    let onStartRecording: () -> Void
    /// 録音停止アクション
    let onStopRecording: () -> Void
    /// デフォルトにリセットするアクション
    let onResetToDefault: () -> Void
    /// ローカライズ設定
    let appLocale: AppLocale

    init(
        keyCombo: Binding<HotKeySettings.KeyComboSettings>,
        defaultKeyCombo: HotKeySettings.KeyComboSettings,
        hotkeyType: HotkeyType,
        isRecording: Bool,
        hotkeyConflict: String?,
        onStartRecording: @escaping () -> Void,
        onStopRecording: @escaping () -> Void,
        onResetToDefault: @escaping () -> Void,
        appLocale: AppLocale
    ) {
        self._keyCombo = keyCombo
        self.defaultKeyCombo = defaultKeyCombo
        self.hotkeyType = hotkeyType
        self.isRecording = isRecording
        self.hotkeyConflict = hotkeyConflict
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording
        self.onResetToDefault = onResetToDefault
        self.appLocale = appLocale
    }

    var body: some View {
        DetailEditCard(
            labelIcon: "keyboard",
            labelText: appLocale.localized("hotkey.shortcut_key"),
            horizontalPadding: 16,
            verticalPadding: 24
        ) {
            VStack(alignment: .center, spacing: 12) {
                // キー設定ボタン
                ShortcutKeyButton(
                    keyCombo: $keyCombo,
                    defaultKeyCombo: defaultKeyCombo,
                    hotkeyType: hotkeyType,
                    isRecording: isRecording,
                    onStartRecording: onStartRecording,
                    onStopRecording: onStopRecording,
                    onResetToDefault: onResetToDefault,
                    appLocale: appLocale
                )

                // 競合警告
                if let conflict = hotkeyConflict {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.footnote)
                        .accessibilityLabel(
                            appLocale.localized("hotkey.accessibility.conflict_warning") + conflict
                        )
                }

                // 注意メッセージ
                Text(appLocale.localized("hotkey.conflict.help"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview("Not Recording") {
    @Previewable @State var keyCombo = HotKeySettings.KeyComboSettings(
        carbonKeyCode: 15,
        carbonModifiers: 768
    )

    ShortcutEditSection(
        keyCombo: $keyCombo,
        defaultKeyCombo: HotKeySettings.KeyComboSettings(
            carbonKeyCode: 15,
            carbonModifiers: 768
        ),
        hotkeyType: .recording,
        isRecording: false,
        hotkeyConflict: nil,
        onStartRecording: {},
        onStopRecording: {},
        onResetToDefault: {},
        appLocale: .system
    )
    .padding()
    .frame(width: 400)
}

#Preview("With Conflict Warning") {
    @Previewable @State var keyCombo = HotKeySettings.KeyComboSettings(
        carbonKeyCode: 15,
        carbonModifiers: 768
    )

    ShortcutEditSection(
        keyCombo: $keyCombo,
        defaultKeyCombo: HotKeySettings.KeyComboSettings(
            carbonKeyCode: 15,
            carbonModifiers: 768
        ),
        hotkeyType: .recording,
        isRecording: false,
        hotkeyConflict: "This shortcut is already used by another application",
        onStartRecording: {},
        onStopRecording: {},
        onResetToDefault: {},
        appLocale: .system
    )
    .padding()
    .frame(width: 400)
}

#Preview("Recording") {
    @Previewable @State var keyCombo = HotKeySettings.KeyComboSettings(
        carbonKeyCode: 0,
        carbonModifiers: 0
    )

    ShortcutEditSection(
        keyCombo: $keyCombo,
        defaultKeyCombo: HotKeySettings.KeyComboSettings(
            carbonKeyCode: 15,
            carbonModifiers: 768
        ),
        hotkeyType: .recording,
        isRecording: true,
        hotkeyConflict: nil,
        onStartRecording: {},
        onStopRecording: {},
        onResetToDefault: {},
        appLocale: .system
    )
    .padding()
    .frame(width: 400)
}
