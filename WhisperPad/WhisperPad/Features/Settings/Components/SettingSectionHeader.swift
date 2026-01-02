//
//  SettingSectionHeader.swift
//  WhisperPad
//

import SwiftUI

/// 設定セクションヘッダー
///
/// 設定画面で使用する統一されたセクションヘッダーコンポーネント。
/// アイコン、タイトル、オプションのヘルプボタンを表示します。
struct SettingSectionHeader: View {
    /// アイコン名
    let icon: String
    /// アイコンの色
    let iconColor: Color
    /// タイトル
    let title: String
    /// ヘルプテキスト（オプション）
    let helpText: String?
    /// フォントサイズ
    let fontSize: CGFloat

    init(
        icon: String,
        iconColor: Color = .accentColor,
        title: String,
        helpText: String? = nil,
        fontSize: CGFloat = 14
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.helpText = helpText
        self.fontSize = fontSize
    }

    var body: some View {
        HStack(spacing: 8) {
            // アイコン
            Image(systemName: icon)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            // タイトル
            Text(title)
                .font(.system(size: fontSize, weight: .semibold))

            Spacer()

            // ヘルプボタン
            if let helpText {
                Button {
                    // ヘルプポップオーバーを表示
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(helpText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(helpText ?? "")
    }
}

// MARK: - Preview

#Preview("Basic") {
    VStack(alignment: .leading, spacing: 16) {
        SettingSectionHeader(
            icon: "waveform",
            iconColor: .blue,
            title: "Audio Input"
        )

        SettingSectionHeader(
            icon: "arrow.up.doc",
            iconColor: .green,
            title: "Output Settings"
        )

        SettingSectionHeader(
            icon: "speaker.slash.fill",
            iconColor: .orange,
            title: "Silence Detection"
        )

        SettingSectionHeader(
            icon: "gear",
            iconColor: .gray,
            title: "Advanced"
        )
    }
    .padding()
    .frame(width: 400)
}

#Preview("With Help") {
    VStack(alignment: .leading, spacing: 16) {
        SettingSectionHeader(
            icon: "waveform",
            iconColor: .blue,
            title: "Audio Input",
            helpText: "Select the microphone to use for recording"
        )

        SettingSectionHeader(
            icon: "speaker.slash.fill",
            iconColor: .orange,
            title: "Silence Detection",
            helpText: "Automatically stop recording when silence is detected"
        )
    }
    .padding()
    .frame(width: 400)
}

#Preview("In Section") {
    Form {
        Section {
            HStack {
                Text("Input Device")
                Spacer()
                Picker("", selection: .constant("default")) {
                    Text("MacBook Pro Microphone").tag("default")
                }
                .labelsHidden()
            }

            HStack {
                Text("Input Level")
                Spacer()
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 8)
                    .frame(maxWidth: 200)
            }
        } header: {
            SettingSectionHeader(
                icon: "waveform",
                iconColor: .blue,
                title: "Audio Input",
                helpText: "Configure audio input settings"
            )
        }

        Section {
            Toggle("Copy to Clipboard", isOn: .constant(true))
            Toggle("Save to File", isOn: .constant(false))
        } header: {
            SettingSectionHeader(
                icon: "arrow.up.doc",
                iconColor: .green,
                title: "Output Settings"
            )
        }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 500, height: 400)
}
