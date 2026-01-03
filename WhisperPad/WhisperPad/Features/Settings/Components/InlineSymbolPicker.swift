//
//  InlineSymbolPicker.swift
//  WhisperPad
//

import SwiftUI

/// インラインでSF Symbolを選択するピッカー
///
/// 推奨シンボルをコンパクトなグリッドで表示し、
/// 追加のシンボルはフルピッカーで選択できます。
struct InlineSymbolPicker: View {
    /// 選択されたシンボル名
    @Binding var selection: String

    /// フルピッカー表示状態
    @State private var showFullPicker = false

    /// 環境ロケール
    @Environment(\.locale) private var locale

    /// クイック選択用の推奨シンボル（2行分 = 14個）
    private let quickSymbols = [
        "mic", "mic.fill", "mic.circle", "waveform", "waveform.badge.mic",
        "record.circle", "pause.fill",
        "stop.fill", "gear", "checkmark.circle", "exclamationmark.triangle",
        "xmark.circle", "speaker.wave.2", "text.bubble"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // クイック選択グリッド
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(36), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(quickSymbols, id: \.self) { symbol in
                    symbolButton(for: symbol)
                }
            }

            // その他のシンボルボタン
            Button {
                showFullPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle")
                    Text("symbol_picker.more_symbols", comment: "More Symbols...")
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showFullPicker) {
                SFSymbolPickerView(
                    selectedSymbol: $selection,
                    isPresented: $showFullPicker
                )
                .environment(\.locale, locale)
            }
        }
    }

    /// シンボル選択ボタン
    @ViewBuilder
    private func symbolButton(for symbol: String) -> some View {
        let isCurrentSelection = selection == symbol

        Button {
            selection = symbol
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(
                    isCurrentSelection
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                )
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isCurrentSelection ? Color.accentColor : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
        .help(symbol)
        .accessibilityLabel(symbol)
        .accessibilityAddTraits(isCurrentSelection ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selection = "mic"

    VStack(alignment: .leading, spacing: 16) {
        Text("アイコン選択")
            .font(.headline)

        InlineSymbolPicker(selection: $selection)

        Text("選択中: \(selection)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 300)
}
