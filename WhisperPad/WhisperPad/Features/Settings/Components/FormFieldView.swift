//
//  FormFieldView.swift
//  WhisperPad
//

import SwiftUI

/// フォームフィールドコンポーネント
///
/// ラベル付きテキストフィールドを表示します。
/// 設定画面のポップオーバーなどで使用できます。
struct FormFieldView: View {
    let label: LocalizedStringKey
    let placeholder: String
    @Binding var text: String
    var accessibilityLabelText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(accessibilityLabelText ?? "")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FormFieldView(
            label: "Title",
            placeholder: "Enter title...",
            text: .constant("Sample Title")
        )
        FormFieldView(
            label: "Description",
            placeholder: "Enter description...",
            text: .constant("")
        )
    }
    .padding()
    .frame(width: 300)
}
