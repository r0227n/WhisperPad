//
//  PopoverHeaderView.swift
//  WhisperPad
//

import SwiftUI

/// ポップオーバーヘッダーコンポーネント
///
/// アイコンとタイトルを含むヘッダーを表示します。
/// 設定画面のポップオーバーで使用できます。
struct PopoverHeaderView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Convenience Initializers

extension PopoverHeaderView {
    /// 文字列タイトルから初期化
    init(icon: String, iconColor: Color, title: String) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = LocalizedStringKey(title)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PopoverHeaderView(
            icon: "doc.text",
            iconColor: .blue,
            title: "File Output"
        )
        PopoverHeaderView(
            icon: "bell",
            iconColor: .orange,
            title: "Notifications"
        )
        PopoverHeaderView(
            icon: "gearshape",
            iconColor: .gray,
            title: "Settings"
        )
    }
    .padding()
}
