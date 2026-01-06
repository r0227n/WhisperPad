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

    init(symbolName: Binding<String>) {
        self._symbolName = symbolName
    }

    var body: some View {
        DetailEditCard(
            labelIcon: "star",
            labelText: "icon.icon"
        ) {
            InlineSymbolPicker(selection: $symbolName)
        }
    }
}

#Preview("Default Icon") {
    @Previewable @State var symbolName = "mic"

    IconEditSection(symbolName: $symbolName)
        .padding()
        .frame(width: 400)
}

#Preview("Recording Icon") {
    @Previewable @State var symbolName = "mic.fill"

    IconEditSection(symbolName: $symbolName)
        .padding()
        .frame(width: 400)
}
