//
//  SettingCard.swift
//  WhisperPad
//

import SwiftUI

/// 設定カード
///
/// 設定項目をグループ化して表示するカードスタイルのコンテナコンポーネント。
/// 背景色、角丸、パディングなどの統一されたスタイルを提供します。
struct SettingCard<Content: View>: View {
    /// カードの内容
    @ViewBuilder var content: () -> Content
    /// パディング
    let padding: CGFloat
    /// 角丸の半径
    let cornerRadius: CGFloat
    /// 背景色
    let backgroundColor: Color

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 8,
        backgroundColor: Color = Color(nsColor: .controlBackgroundColor),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Basic") {
    VStack(spacing: 16) {
        SettingCard {
            Text("This is a setting card")
            Text("It provides a consistent container style")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        SettingCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Input")
                    .font(.headline)
                Picker("Device", selection: .constant("default")) {
                    Text("MacBook Pro Microphone").tag("default")
                }
            }
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Status Card") {
    SettingCard {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("Status: Ready")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Last Recording:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("2 minutes ago")
                }

                HStack {
                    Text("Duration:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("00:45")
                }
            }
            .font(.subheadline)

            HStack(spacing: 8) {
                Button("Test Microphone") {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button("View History") {}
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
    .padding()
    .frame(width: 350)
}

#Preview("Audio Input Card") {
    SettingCard {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Input")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Input Device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: .constant("default")) {
                    Text("MacBook Pro Microphone").tag("default")
                    Text("External Microphone").tag("external")
                }
                .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Input Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .cornerRadius(4)
                    Text("-12 dB")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Multiple Cards") {
    ScrollView {
        VStack(spacing: 16) {
            SettingCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.blue)
                        Text("Audio Input")
                            .font(.headline)
                    }
                    Text("Configure your microphone settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            SettingCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.green)
                        Text("Output Settings")
                            .font(.headline)
                    }
                    Toggle("Copy to Clipboard", isOn: .constant(true))
                    Toggle("Save to File", isOn: .constant(false))
                }
            }

            SettingCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.slash.fill")
                            .foregroundColor(.orange)
                        Text("Silence Detection")
                            .font(.headline)
                    }
                    Toggle("Auto-stop on silence", isOn: .constant(true))
                    HStack {
                        Text("Duration:")
                        Spacer()
                        TextField("", value: .constant(3.0), format: .number)
                            .frame(width: 60)
                        Text("seconds")
                    }
                }
            }
        }
        .padding()
    }
    .frame(width: 400, height: 600)
}

#Preview("Custom Styling") {
    VStack(spacing: 16) {
        SettingCard(
            padding: 20,
            cornerRadius: 12,
            backgroundColor: Color.blue.opacity(0.1)
        ) {
            Text("Custom styled card")
            Text("With larger padding and corner radius")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        SettingCard(
            padding: 12,
            cornerRadius: 4,
            backgroundColor: Color.green.opacity(0.05)
        ) {
            Text("Compact card")
            Text("With smaller padding")
                .font(.caption)
        }
    }
    .padding()
    .frame(width: 400)
}
