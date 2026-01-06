//
//  StorageSection.swift
//  WhisperPad
//

import SwiftUI

/// Storage Section
///
/// Displays storage usage information and location management for model files.
struct StorageSection: View {
    /// ストレージ使用量（バイト）
    let storageUsage: Int64
    /// モデル保存先 URL
    let storageURL: URL?
    /// 場所変更アクション
    let onChangeLocation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("model.storage.section", systemImage: "internaldrive")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("model.storage.usage")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(
                            fromByteCount: storageUsage,
                            countStyle: .file
                        ))
                        .fontWeight(.medium)
                    }

                    HStack {
                        Text("model.storage.location")
                            .foregroundStyle(.secondary)
                        if let url = storageURL {
                            Text(url.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            // Fallback: before path retrieval
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
                }

                Spacer()

                Button("common.change") {
                    onChangeLocation()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    StorageSection(
        storageUsage: 500_000_000,
        storageURL: URL(fileURLWithPath: "/Users/example/Library/Caches/WhisperPad/Models"),
        onChangeLocation: {}
    )
    .padding()
}

#Preview("Loading") {
    StorageSection(
        storageUsage: 0,
        storageURL: nil,
        onChangeLocation: {}
    )
    .padding()
}
