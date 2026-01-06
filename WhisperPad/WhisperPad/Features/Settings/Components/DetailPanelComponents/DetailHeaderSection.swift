//
//  DetailHeaderSection.swift
//  WhisperPad
//

import SwiftUI

/// 詳細パネルのヘッダーセクション
///
/// アイコンプレビュー、タイトル、オプショナルなカテゴリ、リセットボタンを表示します。
/// IconSettingsTabとHotkeySettingsTabで共通利用されます。
struct DetailHeaderSection: View {
    /// SF Symbol名
    let symbolName: String
    /// アイコンの色
    let symbolColor: Color
    /// タイトルテキスト
    let title: String
    /// オプショナルなカテゴリテキスト
    let category: String?
    /// リセットボタンのアクション
    let onReset: () -> Void
    /// リセットボタンのヘルプテキスト
    let resetHelpText: String

    init(
        symbolName: String,
        symbolColor: Color,
        title: String,
        category: String? = nil,
        onReset: @escaping () -> Void,
        resetHelpText: String
    ) {
        self.symbolName = symbolName
        self.symbolColor = symbolColor
        self.title = title
        self.category = category
        self.onReset = onReset
        self.resetHelpText = resetHelpText
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(symbolColor)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(symbolColor.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .help(resetHelpText)
        }
    }
}

#Preview("With Category") {
    VStack(spacing: 24) {
        DetailHeaderSection(
            symbolName: "mic.fill",
            symbolColor: .red,
            title: "Start Recording",
            category: "Recording",
            onReset: {},
            resetHelpText: "Reset to default"
        )

        Divider()

        DetailHeaderSection(
            symbolName: "pause.fill",
            symbolColor: .orange,
            title: "Pause Recording",
            category: "Recording",
            onReset: {},
            resetHelpText: "Reset to default"
        )
    }
    .padding()
    .frame(width: 400)
}

#Preview("Without Category") {
    VStack(spacing: 24) {
        DetailHeaderSection(
            symbolName: "mic",
            symbolColor: Color(nsColor: .systemGray),
            title: "Idle",
            onReset: {},
            resetHelpText: "Reset to default"
        )

        Divider()

        DetailHeaderSection(
            symbolName: "mic.fill",
            symbolColor: Color(nsColor: .systemRed),
            title: "Recording",
            onReset: {},
            resetHelpText: "Reset to default"
        )
    }
    .padding()
    .frame(width: 400)
}
