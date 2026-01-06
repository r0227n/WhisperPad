//
//  IconEditSection.swift
//  WhisperPad
//

import SwiftUI

/// アイコン編集セクション
///
/// InlineSymbolPickerをDetailEditCardでラップしてアイコン選択UIを提供します。
/// IconSettingsTabで使用されます。
struct IconEditSection: View {
    /// 選択中のシンボル名
    @Binding var symbolName: String
    let appLocale: AppLocale

    init(symbolName: Binding<String>, appLocale: AppLocale) {
        self._symbolName = symbolName
        self.appLocale = appLocale
    }

    var body: some View {
        DetailEditCard(
            labelIcon: "star",
            labelText: appLocale.localized("icon.icon")
        ) {
            InlineSymbolPicker(selection: $symbolName, appLocale: appLocale)
        }
    }
}

#Preview("Default Icon") {
    @Previewable @State var symbolName = "mic"

    IconEditSection(symbolName: $symbolName, appLocale: .system)
        .padding()
        .frame(width: 400)
}

#Preview("Recording Icon") {
    @Previewable @State var symbolName = "mic.fill"

    IconEditSection(symbolName: $symbolName, appLocale: .system)
        .padding()
        .frame(width: 400)
}
