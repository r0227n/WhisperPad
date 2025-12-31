//
//  ModelDownloadRow.swift
//  WhisperPad
//

import SwiftUI

/// モデルダウンロード行
///
/// モデルの情報とダウンロード/削除ボタンを表示するリスト行です。
struct ModelDownloadRow: View {
    let model: WhisperModel
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // モデル情報
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .fontWeight(.medium)

                    if model.isRecommended {
                        Text("推奨")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text(model.sizeDisplayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(model.speedDisplayString)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .help("処理速度")

                    Text(model.accuracyDisplayString)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .help("精度")
                }
            }

            Spacer()

            // ダウンロード/削除ボタン
            if isDownloading {
                HStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 60)

                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .help("ダウンロード済み")

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("モデルを削除")
                }
            } else {
                Button {
                    onDownload()
                } label: {
                    Label("ダウンロード", systemImage: "arrow.down.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .help("モデルをダウンロード")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Downloaded") {
    ModelDownloadRow(
        model: WhisperModel.from(id: "openai_whisper-small", isDownloaded: true, isRecommended: true),
        isDownloading: false,
        downloadProgress: 0,
        onDownload: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Not Downloaded") {
    ModelDownloadRow(
        model: WhisperModel.from(id: "openai_whisper-medium", isDownloaded: false, isRecommended: false),
        isDownloading: false,
        downloadProgress: 0,
        onDownload: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Downloading") {
    ModelDownloadRow(
        model: WhisperModel.from(id: "openai_whisper-large-v3", isDownloaded: false, isRecommended: false),
        isDownloading: true,
        downloadProgress: 0.65,
        onDownload: {},
        onDelete: {}
    )
    .padding()
}
