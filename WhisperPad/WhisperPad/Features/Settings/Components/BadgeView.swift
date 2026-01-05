//
//  BadgeView.swift
//  WhisperPad
//

import SwiftUI

/// 汎用バッジコンポーネント
///
/// カプセル型の背景を持つ小さなラベルを表示します。
/// モデルの推奨バッジや言語バッジなど、様々な用途で使用できます。
struct BadgeView: View {
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Convenience Initializers

extension BadgeView {
    /// 文字列から初期化
    init(_ text: String, color: Color) {
        self.text = LocalizedStringKey(text)
        self.color = color
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        BadgeView(text: "model.active.recommended", color: .accentColor)
        BadgeView("EN", color: .blue)
        BadgeView("New", color: .green)
        BadgeView("Beta", color: .orange)
    }
    .padding()
}
