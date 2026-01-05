//
//  StorageSection.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Storage Section
///
/// Displays storage usage information and location management for model files.
struct StorageSection: View {
    @Bindable var store: StoreOf<SettingsFeature>

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
                            fromByteCount: store.storageUsage,
                            countStyle: .file
                        ))
                        .fontWeight(.medium)
                    }

                    HStack {
                        Text("model.storage.location")
                            .foregroundStyle(.secondary)
                        if let storageURL = store.modelStorageURL {
                            Text(storageURL.path)
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
                    store.send(.selectStorageLocation)
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
        store: Store(
            initialState: SettingsFeature.State(
                storageUsage: 500_000_000,
                modelStorageURL: URL(fileURLWithPath: "/Users/example/Library/Caches/WhisperPad/Models")
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
}

#Preview("Loading") {
    StorageSection(
        store: Store(
            initialState: SettingsFeature.State(
                storageUsage: 0,
                modelStorageURL: nil
            )
        ) {
            SettingsFeature()
        }
    )
    .padding()
}
