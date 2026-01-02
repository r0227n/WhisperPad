//
//  InfoPopoverButton.swift
//  WhisperPad
//

import SwiftUI

/// 情報ポップオーバーボタン
///
/// 小さな情報アイコンボタンで、クリックするとヘルプテキストを表示します。
/// 設定項目の補足説明を提供するために使用します。
struct InfoPopoverButton: View {
    /// ヘルプテキスト
    let helpText: String
    /// ポップオーバーのタイトル（オプション）
    let title: String?
    /// アイコンサイズ
    let iconSize: CGFloat

    @State private var isShowingPopover = false

    init(
        helpText: String,
        title: String? = nil,
        iconSize: CGFloat = 14
    ) {
        self.helpText = helpText
        self.title = title
        self.iconSize = iconSize
    }

    var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: iconSize))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    Text(title)
                        .font(.headline)
                }

                Text(helpText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: 300)
        }
        .accessibilityLabel("Help")
        .accessibilityHint(helpText)
    }
}

// MARK: - Preview

#Preview("Basic") {
    HStack(spacing: 16) {
        Text("Silence Threshold:")
        InfoPopoverButton(
            helpText: "The audio level below which silence is detected. Lower values are more sensitive to silence."
        )

        Text("Sample Rate:")
        InfoPopoverButton(
            helpText: "The number of audio samples per second. Higher rates provide better quality but use more storage."
        )
    }
    .padding()
}

#Preview("With Title") {
    VStack(spacing: 16) {
        HStack {
            Text("Silence Detection")
            InfoPopoverButton(
                helpText: "When enabled, recording automatically stops after the specified duration of silence. This is useful for hands-free recording.",
                title: "About Silence Detection"
            )
        }

        HStack {
            Text("Audio Quality")
            InfoPopoverButton(
                helpText: "Higher quality settings provide better transcription accuracy but use more storage space and processing power.",
                title: "Audio Quality Settings"
            )
        }
    }
    .padding()
}

#Preview("Different Sizes") {
    VStack(spacing: 12) {
        HStack {
            Text("Small:")
            InfoPopoverButton(helpText: "This is a small icon", iconSize: 12)
        }

        HStack {
            Text("Medium:")
            InfoPopoverButton(helpText: "This is a medium icon", iconSize: 14)
        }

        HStack {
            Text("Large:")
            InfoPopoverButton(helpText: "This is a large icon", iconSize: 16)
        }
    }
    .padding()
}

#Preview("In Form") {
    Form {
        Section {
            HStack {
                Text("無音判定時間")
                InfoPopoverButton(
                    helpText: "この時間だけ無音が続くと、録音を自動的に停止します。",
                    title: "無音判定時間について"
                )
                Spacer()
                TextField("秒", value: .constant(3.0), format: .number)
                    .frame(width: 80)
                Text("秒")
            }

            HStack {
                Text("無音判定しきい値")
                InfoPopoverButton(
                    helpText: "このレベル以下の音声を無音として扱います。-40dB がデフォルトです。",
                    title: "無音判定しきい値について"
                )
                Spacer()
                Text("-40 dB")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("無音検出")
        }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 500, height: 200)
}
