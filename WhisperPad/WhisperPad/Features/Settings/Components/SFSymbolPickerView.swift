//
//  SFSymbolPickerView.swift
//  WhisperPad
//

import SwiftUI

/// SF Symbol picker view
///
/// Provides grid display of recommended symbols and search functionality.
struct SFSymbolPickerView: View {
    /// Selected symbol name
    @Binding var selectedSymbol: String

    /// Sheet display state
    @Binding var isPresented: Bool

    /// Search text
    @State private var searchText = ""

    /// Recommended symbols (audio/media related)
    private let recommendedSymbols = [
        // Microphone
        "mic",
        "mic.fill",
        "mic.circle",
        "mic.circle.fill",
        "mic.slash",
        "mic.slash.fill",
        "mic.badge.plus",
        // Waveform
        "waveform",
        "waveform.circle",
        "waveform.circle.fill",
        "waveform.badge.mic",
        "waveform.badge.plus",
        // Play/Stop
        "play",
        "play.fill",
        "play.circle",
        "play.circle.fill",
        "pause",
        "pause.fill",
        "pause.circle",
        "pause.circle.fill",
        "stop",
        "stop.fill",
        "stop.circle",
        "stop.circle.fill",
        "record.circle",
        "record.circle.fill",
        // Gear/Settings
        "gear",
        "gearshape",
        "gearshape.fill",
        "gearshape.2",
        "gearshape.2.fill",
        // Checkmark
        "checkmark",
        "checkmark.circle",
        "checkmark.circle.fill",
        "checkmark.seal",
        "checkmark.seal.fill",
        // Warning/Error
        "exclamationmark.triangle",
        "exclamationmark.triangle.fill",
        "exclamationmark.circle",
        "exclamationmark.circle.fill",
        "xmark",
        "xmark.circle",
        "xmark.circle.fill",
        // Text/Document
        "doc.text",
        "doc.text.fill",
        "text.bubble",
        "text.bubble.fill",
        "bubble.left",
        "bubble.left.fill",
        // Speaker
        "speaker.wave.1",
        "speaker.wave.2",
        "speaker.wave.3",
        "speaker.slash",
        // Others
        "bolt",
        "bolt.fill",
        "bolt.circle",
        "bolt.circle.fill",
        "star",
        "star.fill",
        "heart",
        "heart.fill",
        "hand.raised",
        "hand.raised.fill",
        "pencil",
        "pencil.circle",
        "pencil.circle.fill"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.get(.symbolPickerSelectIcon))
                    .font(.headline)
                Spacer()
                Button(L10n.get(.symbolPickerClose)) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n.get(.modelSearchPlaceholder), text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Symbol grid
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 50))],
                    spacing: 10
                ) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            isPresented = false
                        } label: {
                            VStack {
                                Image(systemName: symbol)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                            }
                            .frame(width: 50, height: 50)
                            .background(
                                selectedSymbol == symbol
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selectedSymbol == symbol
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .help(symbol)
                    }
                }
                .padding()
            }

            Divider()

            // Footer (current selection)
            HStack {
                Text(L10n.get(.symbolPickerSelected))
                    .foregroundColor(.secondary)
                Image(systemName: selectedSymbol)
                    .font(.system(size: 16))
                Text(selectedSymbol)
                    .font(.system(.body, design: .monospaced))
                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }

    /// Filtered symbol list
    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return recommendedSymbols
        }
        return recommendedSymbols.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedSymbol = "mic"
    @Previewable @State var isPresented = true

    SFSymbolPickerView(
        selectedSymbol: $selectedSymbol,
        isPresented: $isPresented
    )
}
