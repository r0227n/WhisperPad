//
//  IconConfigurationView.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// 各状態のアイコンと色を編集するコンポーネント
///
/// 1行で状態名、プレビュー、アイコン変更ボタン、カラーピッカーを表示します。
struct IconConfigurationView: View {
    /// 状態タイプ
    let status: IconConfigStatus

    /// アイコン設定
    @Binding var config: StatusIconConfig

    /// シンボルピッカーの表示状態
    @State private var showSymbolPicker = false

    /// 選択された色（SwiftUI用）
    @State private var selectedColor: Color

    /// イニシャライザ
    /// - Parameters:
    ///   - status: 状態タイプ
    ///   - config: アイコン設定のバインディング
    init(status: IconConfigStatus, config: Binding<StatusIconConfig>) {
        self.status = status
        self._config = config
        // NSColor を SwiftUI の Color に変換
        self._selectedColor = State(initialValue: Color(nsColor: config.wrappedValue.color))
    }

    var body: some View {
        HStack(spacing: 12) {
            // 状態名
            Text(status.rawValue)
                .frame(width: 120, alignment: .leading)

            // プレビュー（クリックでアイコン変更ダイアログを開く）
            Button {
                showSymbolPicker = true
            } label: {
                Image(systemName: config.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(selectedColor)
                    .font(.system(size: 20))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .help("クリックしてアイコンを変更")
            .accessibilityLabel("\(status.rawValue)のアイコンを変更")
            .accessibilityHint("アイコン選択画面を開きます")
            .sheet(isPresented: $showSymbolPicker) {
                SFSymbolPickerView(
                    selectedSymbol: $config.symbolName,
                    isPresented: $showSymbolPicker
                )
            }

            // 色選択
            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .frame(width: 44)
                .onChange(of: selectedColor) { _, newColor in
                    config.color = NSColor(newColor)
                }
                .help("アイコンの色を選択")
                .accessibilityLabel("\(status.rawValue)のアイコンの色")
                .accessibilityHint("アイコンの色を選択します")

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(status.rawValue)のアイコン設定: \(config.symbolName)")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var config = StatusIconConfig(symbolName: "mic", color: .systemGray)

    Form {
        Section("アイコン設定") {
            IconConfigurationView(
                status: .idle,
                config: $config
            )
            IconConfigurationView(
                status: .recording,
                config: .constant(StatusIconConfig(symbolName: "mic.fill", color: .systemRed))
            )
            IconConfigurationView(
                status: .completed,
                config: .constant(StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen))
            )
        }
    }
    .formStyle(.grouped)
    .frame(width: 500)
    .padding()
}
