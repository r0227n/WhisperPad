//
//  DetailPanelContainer.swift
//  WhisperPad
//

import SwiftUI

/// 詳細パネル用のスクロール可能なコンテナ
///
/// ScrollView + VStack構造を提供し、詳細パネルの共通レイアウトを実現します。
/// IconSettingsTabとHotkeySettingsTabで共通利用されます。
struct DetailPanelContainer<Content: View>: View {
    /// 外側のパディング
    let padding: CGFloat
    /// VStackの垂直方向スペーシング
    let spacing: CGFloat
    /// コンテンツビルダー
    @ViewBuilder let content: () -> Content

    init(
        padding: CGFloat = 24,
        spacing: CGFloat = 24,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content()

                Spacer(minLength: 0)
            }
            .padding(padding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Basic Detail Panel") {
    DetailPanelContainer {
        Text("Header Section")
            .font(.title2)
            .bold()

        Divider()

        Text("Description Section")
            .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Section")
                .font(.headline)
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .frame(height: 100)
                .cornerRadius(8)
        }
    }
    .frame(width: 400, height: 500)
}

#Preview("Custom Spacing and Padding") {
    DetailPanelContainer(padding: 32, spacing: 16) {
        Text("Larger Padding")
            .font(.title2)

        Divider()

        ForEach(0 ..< 5) { index in
            Text("Item \(index + 1)")
                .padding(.vertical, 4)
        }
    }
    .frame(width: 400, height: 500)
}
