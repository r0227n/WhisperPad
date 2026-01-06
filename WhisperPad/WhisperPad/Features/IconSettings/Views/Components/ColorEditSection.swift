//
//  ColorEditSection.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// 色編集セクション
///
/// ColorPicker + プリセット色ボタンを提供し、Color <-> NSColor の同期を管理します。
/// IconSettingsTabで使用されます。
struct ColorEditSection: View {
    /// SwiftUI Color バインディング
    @Binding var selectedColor: Color
    /// NSColor バインディング
    @Binding var nsColor: NSColor
    /// プリセット色の配列
    let presetColors: [NSColor]

    /// デフォルトのプリセット色
    static let defaultPresetColors: [NSColor] = [
        .systemGray,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemBlue,
        .systemGreen,
        .systemPurple
    ]

    init(
        selectedColor: Binding<Color>,
        nsColor: Binding<NSColor>,
        presetColors: [NSColor] = ColorEditSection.defaultPresetColors
    ) {
        self._selectedColor = selectedColor
        self._nsColor = nsColor
        self.presetColors = presetColors
    }

    var body: some View {
        DetailEditCard(
            labelIcon: "paintpalette",
            labelText: "icon.color"
        ) {
            HStack(spacing: 8) {
                // ColorPicker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 44, height: 24)

                Divider()
                    .frame(height: 24)

                // プリセット色ボタン
                ForEach(presetColors, id: \.self) { presetColor in
                    presetColorButton(for: presetColor)
                }
            }
        }
        .onChange(of: selectedColor) { _, newColor in
            // SwiftUI Color -> NSColor への同期
            nsColor = NSColor(newColor)
        }
        .onChange(of: nsColor) { _, newNSColor in
            // NSColor -> SwiftUI Color への同期
            selectedColor = Color(nsColor: newNSColor)
        }
    }

    /// プリセット色ボタン
    @ViewBuilder
    private func presetColorButton(for presetColor: NSColor) -> some View {
        let isSelected = nsColor.isApproximatelyEqual(to: presetColor)

        Button {
            nsColor = presetColor
            selectedColor = Color(nsColor: presetColor)
        } label: {
            Circle()
                .fill(Color(nsColor: presetColor))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    isSelected
                        ? Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        : nil
                )
        }
        .buttonStyle(.plain)
        .help(presetColor.localizedName)
        .accessibilityLabel(presetColor.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - NSColor Extension

private extension NSColor {
    /// 2つの色が近似的に等しいかを判定
    func isApproximatelyEqual(to other: NSColor, tolerance: CGFloat = 0.01) -> Bool {
        guard let selfRGB = self.usingColorSpace(.sRGB),
              let otherRGB = other.usingColorSpace(.sRGB)
        else {
            return false
        }

        return abs(selfRGB.redComponent - otherRGB.redComponent) < tolerance
            && abs(selfRGB.greenComponent - otherRGB.greenComponent) < tolerance
            && abs(selfRGB.blueComponent - otherRGB.blueComponent) < tolerance
    }

    /// ローカライズされた色名
    var localizedName: String {
        switch self {
        case .systemGray:
            String(localized: "color.gray", defaultValue: "Gray", comment: "Gray color")
        case .systemRed:
            String(localized: "color.red", defaultValue: "Red", comment: "Red color")
        case .systemOrange:
            String(localized: "color.orange", defaultValue: "Orange", comment: "Orange color")
        case .systemYellow:
            String(localized: "color.yellow", defaultValue: "Yellow", comment: "Yellow color")
        case .systemBlue:
            String(localized: "color.blue", defaultValue: "Blue", comment: "Blue color")
        case .systemGreen:
            String(localized: "color.green", defaultValue: "Green", comment: "Green color")
        case .systemPurple:
            String(localized: "color.purple", defaultValue: "Purple", comment: "Purple color")
        default:
            String(localized: "color.custom", defaultValue: "Custom", comment: "Custom color")
        }
    }
}

#Preview("Default Colors") {
    @Previewable @State var selectedColor = Color.red
    @Previewable @State var nsColor: NSColor = .systemRed

    ColorEditSection(
        selectedColor: $selectedColor,
        nsColor: $nsColor
    )
    .padding()
    .frame(width: 400)
}

#Preview("Custom Preset Colors") {
    @Previewable @State var selectedColor = Color.blue
    @Previewable @State var nsColor: NSColor = .systemBlue

    ColorEditSection(
        selectedColor: $selectedColor,
        nsColor: $nsColor,
        presetColors: [.systemRed, .systemBlue, .systemGreen]
    )
    .padding()
    .frame(width: 400)
}
