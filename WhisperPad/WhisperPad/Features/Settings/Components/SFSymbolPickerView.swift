//
//  SFSymbolPickerView.swift
//  WhisperPad
//

import SwiftUI

/// SF Symbol を選択するためのピッカービュー
///
/// 推奨シンボルのグリッド表示と検索機能を提供します。
struct SFSymbolPickerView: View {
    /// 選択されたシンボル名
    @Binding var selectedSymbol: String

    /// シートの表示状態
    @Binding var isPresented: Bool

    let appLocale: AppLocale

    /// 検索テキスト
    @State private var searchText = ""

    /// 推奨シンボル（音声・メディア関連）
    private let recommendedSymbols = [
        // マイク系
        "mic",
        "mic.fill",
        "mic.circle",
        "mic.circle.fill",
        "mic.slash",
        "mic.slash.fill",
        "mic.badge.plus",
        // 波形系
        "waveform",
        "waveform.circle",
        "waveform.circle.fill",
        "waveform.badge.mic",
        "waveform.badge.plus",
        // 再生・停止系
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
        // 歯車・設定系
        "gear",
        "gearshape",
        "gearshape.fill",
        "gearshape.2",
        "gearshape.2.fill",
        // チェックマーク系
        "checkmark",
        "checkmark.circle",
        "checkmark.circle.fill",
        "checkmark.seal",
        "checkmark.seal.fill",
        // 警告・エラー系
        "exclamationmark.triangle",
        "exclamationmark.triangle.fill",
        "exclamationmark.circle",
        "exclamationmark.circle.fill",
        "xmark",
        "xmark.circle",
        "xmark.circle.fill",
        // テキスト・ドキュメント系
        "doc.text",
        "doc.text.fill",
        "text.bubble",
        "text.bubble.fill",
        "bubble.left",
        "bubble.left.fill",
        // スピーカー系
        "speaker.wave.1",
        "speaker.wave.2",
        "speaker.wave.3",
        "speaker.slash",
        // その他
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
            // ヘッダー
            HStack {
                Text(appLocale.localized("symbol_picker.title"))
                    .font(.headline)
                Spacer()
                Button(appLocale.localized("common.close")) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // 検索フィールド
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(
                    appLocale.localized("symbol_picker.search_placeholder"),
                    text: $searchText
                )
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

            // シンボルグリッド
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

            // フッター（現在の選択）
            HStack {
                Text(appLocale.localized("symbol_picker.selected"))
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

    /// フィルタリングされたシンボル一覧
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
        isPresented: $isPresented,
        appLocale: .system
    )
}
