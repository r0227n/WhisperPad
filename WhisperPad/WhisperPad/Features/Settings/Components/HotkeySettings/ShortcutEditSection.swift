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

    init(
        keyCombo: Binding<HotKeySettings.KeyComboSettings>,
        defaultKeyCombo: HotKeySettings.KeyComboSettings,
        hotkeyType: HotkeyType,
        isRecording: Bool,
        hotkeyConflict: String?,
        onStartRecording: @escaping () -> Void,
        onStopRecording: @escaping () -> Void,
        onResetToDefault: @escaping () -> Void
    ) {
        self._keyCombo = keyCombo
        self.defaultKeyCombo = defaultKeyCombo
        self.hotkeyType = hotkeyType
        self.isRecording = isRecording
        self.hotkeyConflict = hotkeyConflict
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording
        self.onResetToDefault = onResetToDefault
    }

    var body: some View {
        DetailEditCard(
            labelIcon: "keyboard",
            labelText: "hotkey.shortcut_key",
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
                    onResetToDefault: onResetToDefault
                )

                // 競合警告
                if let conflict = hotkeyConflict {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.footnote)
                        .accessibilityLabel(
                            String(
                                localized: "hotkey.accessibility.conflict_warning",
                                defaultValue: "Shortcut conflict warning: ",
                                comment: "Shortcut conflict warning: "
                            ) + conflict
                        )
                }

                // 注意メッセージ
                Text("hotkey.conflict.help")
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
        onResetToDefault: {}
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
        onResetToDefault: {}
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
        onResetToDefault: {}
    )
    .padding()
    .frame(width: 400)
}
