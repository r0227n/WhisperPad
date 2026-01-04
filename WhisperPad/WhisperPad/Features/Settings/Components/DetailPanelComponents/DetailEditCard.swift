//
//  DetailEditCard.swift
//  WhisperPad
//

import AppKit
import SwiftUI

/// 詳細パネルの編集カードコンテナ
///
/// ラベル付きの角丸背景カードを提供します。
/// アイコン編集、カラー編集、ショートカット入力などで使用されます。
struct DetailEditCard<Content: View>: View {
    /// ラベルのSF Symbol
    let labelIcon: String
    /// ラベルテキスト
    let labelText: LocalizedStringKey
    /// 内部パディング
    let padding: EdgeInsets
    /// 角の丸み
    let cornerRadius: CGFloat
    /// 背景色
    let backgroundColor: Color
    /// コンテンツビルダー
    @ViewBuilder let content: () -> Content

    init(
        labelIcon: String,
        labelText: LocalizedStringKey,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = Color(nsColor: .controlBackgroundColor),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.labelIcon = labelIcon
        self.labelText = labelText
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content
    }

    /// 水平・垂直パディングを個別指定する便利イニシャライザ
    init(
        labelIcon: String,
        labelText: LocalizedStringKey,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = Color(nsColor: .controlBackgroundColor),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.labelIcon = labelIcon
        self.labelText = labelText
        self.padding = EdgeInsets(
            top: verticalPadding,
            leading: horizontalPadding,
            bottom: verticalPadding,
            trailing: horizontalPadding
        )
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Label {
                Text(labelText)
                    .font(.headline)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: labelIcon)
                    .foregroundColor(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(padding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
    }
}

#Preview("Basic Card") {
    DetailEditCard(
        labelIcon: "star",
        labelText: "Icon Selection"
    ) {
        HStack(spacing: 12) {
            ForEach(["star", "heart", "circle", "square"], id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Custom Padding") {
    DetailEditCard(
        labelIcon: "keyboard",
        labelText: "Shortcut Key",
        horizontalPadding: 16,
        verticalPadding: 24
    ) {
        VStack(spacing: 8) {
            Text("Press a key combination")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(height: 44)
                .overlay {
                    Text("⌘⌥R")
                        .font(.headline)
                }
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Multiple Cards") {
    VStack(spacing: 16) {
        DetailEditCard(
            labelIcon: "paintpalette",
            labelText: "Color"
        ) {
            HStack(spacing: 8) {
                ForEach(["red", "orange", "yellow", "green", "blue"], id: \.self) { color in
                    Circle()
                        .fill(Color(color))
                        .frame(width: 32, height: 32)
                }
            }
        }

        DetailEditCard(
            labelIcon: "textformat.size",
            labelText: "Font Size"
        ) {
            HStack {
                Text("A")
                    .font(.caption)
                Slider(value: .constant(0.5))
                Text("A")
                    .font(.title)
            }
        }
    }
    .padding()
    .frame(width: 400)
}
