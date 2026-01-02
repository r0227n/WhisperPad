//
//  ModelListRow.swift
//  WhisperPad
//

import SwiftUI

/// モデルリスト行
///
/// モデル情報をリスト行形式で表示するコンポーネント。
struct ModelListRow: View {
    let model: WhisperModel
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // ダウンロード済みアイコン
            downloadStatusIcon

            // モデル名とバッジ
            modelNameSection

            Spacer()

            // アクションボタン
            actionSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Download Status Icon

    private var downloadStatusIcon: some View {
        Group {
            if model.isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help("ダウンロード済み")
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .help("未ダウンロード")
            }
        }
        .font(.system(size: 14))
        .frame(width: 20)
    }

    // MARK: - Model Name Section

    private var modelNameSection: some View {
        HStack(spacing: 6) {
            Text(model.displayName)
                .font(.system(size: 13, weight: .medium))

            if model.isRecommended {
                Text("推奨")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            if isEnglishOnly {
                Text("EN")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundStyle(Color.blue)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    private var actionSection: some View {
        if isDownloading {
            downloadingView
        } else if model.isDownloaded {
            downloadedView
        } else {
            notDownloadedView
        }
    }

    private var downloadingView: some View {
        HStack(spacing: 8) {
            ProgressView(value: downloadProgress)
                .progressViewStyle(.linear)
                .frame(width: 80)
                .accessibilityLabel("\(model.displayName)のダウンロード進捗")
                .accessibilityValue("\(Int(downloadProgress * 100))パーセント")

            Text("\(Int(downloadProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var downloadedView: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("削除", systemImage: "trash")
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("モデルを削除")
        .accessibilityLabel("\(model.displayName)を削除")
        .accessibilityHint("モデルを削除します。再度使用するにはダウンロードが必要です")
    }

    private var notDownloadedView: some View {
        Button {
            onDownload()
        } label: {
            Label("ダウンロード", systemImage: "arrow.down.circle")
                .font(.caption)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .help("モデルをダウンロード")
        .accessibilityLabel("\(model.displayName)をダウンロード")
        .accessibilityHint("モデルをダウンロードしてオフラインで使用できるようにします")
    }

    // MARK: - Helpers

    private var isEnglishOnly: Bool {
        model.id.hasSuffix(".en")
    }

    private var accessibilityDescription: String {
        var parts = [model.displayName]
        if model.isRecommended {
            parts.append("推奨")
        }
        if isEnglishOnly {
            parts.append("英語専用")
        }
        if model.isDownloaded {
            parts.append("ダウンロード済み")
        }
        return parts.joined(separator: "、")
    }
}

// MARK: - Preview

#Preview("Downloaded") {
    VStack(spacing: 0) {
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-small", isDownloaded: true, isRecommended: true),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 480)
}

#Preview("Not Downloaded") {
    VStack(spacing: 0) {
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-medium", isDownloaded: false, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-small.en", isDownloaded: false, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 480)
}

#Preview("Downloading") {
    ModelListRow(
        model: WhisperModel.from(id: "openai_whisper-large-v3", isDownloaded: false, isRecommended: false),
        isDownloading: true,
        downloadProgress: 0.65,
        onDownload: {},
        onDelete: {}
    )
    .padding()
    .frame(width: 480)
}

#Preview("List") {
    VStack(spacing: 0) {
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-small", isDownloaded: true, isRecommended: true),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-medium", isDownloaded: false, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {}
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-large-v3", isDownloaded: false, isRecommended: false),
            isDownloading: true,
            downloadProgress: 0.45,
            onDownload: {},
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 480)
}
