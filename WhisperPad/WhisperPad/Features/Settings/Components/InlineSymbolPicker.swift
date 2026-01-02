//
//  InlineSymbolPicker.swift
//  WhisperPad
//

import SwiftUI

/// Inline SF Symbol picker
///
/// Displays recommended symbols in a compact grid,
/// and additional symbols can be selected via full picker.
struct InlineSymbolPicker: View {
    /// Selected symbol name
    @Binding var selection: String

    /// Full picker display state
    @State private var showFullPicker = false

    /// Recommended symbols for quick selection (2 rows = 14 items)
    private let quickSymbols = [
        "mic", "mic.fill", "mic.circle", "waveform", "waveform.badge.mic",
        "record.circle", "pause.fill",
        "stop.fill", "gear", "checkmark.circle", "exclamationmark.triangle",
        "xmark.circle", "speaker.wave.2", "text.bubble"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quick selection grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(36), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(quickSymbols, id: \.self) { symbol in
                    symbolButton(for: symbol)
                }
            }

            // More symbols button
            Button {
                showFullPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle")
                    Text(L10n.get(.symbolPickerMore))
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
            }
        }
    }

    /// Symbol selection button
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
        Text("Icon Selection")
            .font(.headline)

        InlineSymbolPicker(selection: $selection)

        Text("Selected: \(selection)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 300)
}
