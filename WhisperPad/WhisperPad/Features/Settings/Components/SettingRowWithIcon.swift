//
//  SettingRowWithIcon.swift
//  WhisperPad
//

import SwiftUI

/// アイコン付き設定行
///
/// 設定項目をアイコンとともに表示する再利用可能なコンポーネント
struct SettingRowWithIcon<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 20, alignment: .center)

            Text(title)

            Spacer()

            content()
        }
    }
}

// MARK: - Convenience Initializer

extension SettingRowWithIcon where Content == AnyView {
    /// Toggle用の簡易イニシャライザ
    init(
        icon: String,
        iconColor: Color,
        title: String,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = {
            AnyView(
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    Form {
        Section {
            SettingRowWithIcon(
                icon: "power",
                iconColor: .green,
                title: "ログイン時に起動",
                isOn: .constant(true)
            )

            SettingRowWithIcon(
                icon: "bell.fill",
                iconColor: .orange,
                title: "通知を表示"
            ) {
                Toggle("", isOn: .constant(false))
                    .labelsHidden()
            }

            SettingRowWithIcon(
                icon: "doc.on.clipboard",
                iconColor: .blue,
                title: "クリップボードにコピー"
            ) {
                HStack {
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                    Button {} label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    .formStyle(.grouped)
    .frame(width: 400, height: 200)
}
