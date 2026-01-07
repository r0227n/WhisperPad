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
    let appLocale: AppLocale

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
    }

    // MARK: - Download Status Icon

    private var downloadStatusIcon: some View {
        Group {
            if model.isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help(appLocale.localized("model.row.downloaded"))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .help(appLocale.localized("model.row.not_downloaded"))
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
                .accessibilityLabel(
                    String(
                        format: appLocale.localized("model.row.download_progress"),
                        model.displayName
                    )
                )
                .accessibilityValue(
                    String(
                        format: appLocale.localized("model.row.percentage.label"),
                        Int(downloadProgress * 100)
                    )
                )

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
            Label {
                Text(appLocale.localized("common.delete"))
            } icon: {
                Image(systemName: "trash")
            }
            .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(appLocale.localized("model.row.delete.help"))
        .accessibilityLabel(
            String(
                format: appLocale.localized("model.row.delete.label %@"),
                model.displayName
            )
        )
        .accessibilityHint(appLocale.localized("model.row.delete.hint"))
    }

    private var notDownloadedView: some View {
        Button {
            onDownload()
        } label: {
            Label {
                Text(appLocale.localized("model.row.download.button"))
            } icon: {
                Image(systemName: "arrow.down.circle")
            }
            .font(.caption)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .help(appLocale.localized("model.row.download.help"))
        .accessibilityLabel(
            String(
                format: appLocale.localized("model.row.download.label"),
                model.displayName
            )
        )
        .accessibilityHint(appLocale.localized("model.row.download.hint"))
    }

    // MARK: - Helpers

    private var isEnglishOnly: Bool {
        model.id.hasSuffix(".en")
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
            onDelete: {},
            appLocale: .system
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-tiny", isDownloaded: true, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {},
            appLocale: .system
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
            onDelete: {},
            appLocale: .system
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-small.en", isDownloaded: false, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {},
            appLocale: .system
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
        onDelete: {},
        appLocale: .system
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
            onDelete: {},
            appLocale: .system
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-small", isDownloaded: true, isRecommended: true),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {},
            appLocale: .system
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-medium", isDownloaded: false, isRecommended: false),
            isDownloading: false,
            downloadProgress: 0,
            onDownload: {},
            onDelete: {},
            appLocale: .system
        )
        Divider()
        ModelListRow(
            model: WhisperModel.from(id: "openai_whisper-large-v3", isDownloaded: false, isRecommended: false),
            isDownloading: true,
            downloadProgress: 0.45,
            onDownload: {},
            onDelete: {},
            appLocale: .system
        )
    }
    .padding()
    .frame(width: 480)
}
