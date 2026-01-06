//
//  DetailDescriptionSection.swift
//  WhisperPad
//

import SwiftUI

/// 詳細パネルの説明セクション
///
/// infoアイコン付きのラベルと説明テキストを表示します。
/// IconSettingsTabとHotkeySettingsTabで共通利用されます。
struct DetailDescriptionSection: View {
    /// 説明テキスト
    let descriptionText: String
    /// ラベルテキスト
    let labelText: String

    init(descriptionText: String, labelText: String = "Description") {
        self.descriptionText = descriptionText
        self.labelText = labelText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(labelText)
                    .font(.headline)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }

            Text(descriptionText)
                .foregroundColor(.primary)
        }
    }
}

#Preview("Basic Description") {
    DetailDescriptionSection(
        descriptionText: "This is a sample description text that explains what this setting does."
    )
    .padding()
    .frame(width: 400)
}

#Preview("Long Description") {
    DetailDescriptionSection(
        descriptionText: """
        This is a longer description that spans multiple lines. \
        It provides detailed information about the feature and \
        how it can be configured by the user.
        """
    )
    .padding()
    .frame(width: 400)
}

#Preview("In Context") {
    VStack(alignment: .leading, spacing: 24) {
        Text("Feature Title")
            .font(.title2)
            .fontWeight(.semibold)

        Divider()

        DetailDescriptionSection(
            descriptionText: "Configure this setting to customize your experience."
        )

        Divider()

        Text("Additional Controls")
            .font(.headline)
    }
    .padding()
    .frame(width: 400)
}
