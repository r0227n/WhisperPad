//
//  HoverPopoverButton.swift
//  WhisperPad
//

import SwiftUI

/// ホバーでポップオーバーを表示するボタン
///
/// マウスホバーまたはクリックでポップオーバーを表示する設定用コンポーネント
struct HoverPopoverButton<Content: View>: View {
    let label: LocalizedStringKey
    let icon: String
    @ViewBuilder var popoverContent: () -> Content

    @Environment(\.locale) private var locale
    @State private var isShowingPopover = false
    @State private var isHovering = false

    var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12))
            }
            .foregroundStyle(isHovering ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
            if hovering {
                // ホバー開始から少し遅延してポップオーバーを表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isHovering {
                        isShowingPopover = true
                    }
                }
            }
        }
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            popoverContent()
                .environment(\.locale, locale)
                .padding()
                .frame(minWidth: 280)
        }
        .accessibilityLabel(label)
        .accessibilityHint(String(localized: "accessibility.show_details", comment: "Show detailed settings"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HoverPopoverButton(label: "詳細設定", icon: "gearshape") {
            VStack(alignment: .leading, spacing: 12) {
                Text("詳細設定")
                    .font(.headline)
                TextField("タイトル", text: .constant("WhisperPad"))
                    .textFieldStyle(.roundedBorder)
                Toggle("オプション", isOn: .constant(true))
            }
        }

        HoverPopoverButton(label: "ファイル設定", icon: "folder") {
            VStack(alignment: .leading, spacing: 12) {
                Text("ファイル出力設定")
                    .font(.headline)
                Text("保存先: ~/Documents/WhisperPad")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
    .frame(width: 300, height: 200)
}
