//
//  ModelSearchFilterBar.swift
//  WhisperPad
//

import SwiftUI

/// モデル検索・フィルターバー
///
/// モデル一覧の検索とフィルタリングを行うコンポーネント。
struct ModelSearchFilterBar: View {
    @Binding var searchText: String
    @Binding var downloadFilter: ModelDownloadFilter
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 検索フィールド
            searchField

            // フィルター行
            filterRow
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))

                TextField("モデルを検索...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("検索をクリア")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)

            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isLoading)
            .help("モデル一覧を更新")
        }
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        HStack(spacing: 16) {
            // ダウンロード状態フィルター
            filterPicker(
                label: "状態",
                selection: $downloadFilter,
                options: ModelDownloadFilter.allCases
            ) { $0.displayName }

            Spacer()
        }
    }

    // MARK: - Filter Picker

    private func filterPicker<T: Hashable>(
        label: String,
        selection: Binding<T>,
        options: [T],
        displayName: @escaping (T) -> String
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @State private var downloadFilter = ModelDownloadFilter.all

        var body: some View {
            ModelSearchFilterBar(
                searchText: $searchText,
                downloadFilter: $downloadFilter,
                isLoading: false,
                onRefresh: {}
            )
            .padding()
            .frame(width: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("With Search Text") {
    struct PreviewWrapper: View {
        @State private var searchText = "small"
        @State private var downloadFilter = ModelDownloadFilter.downloaded

        var body: some View {
            ModelSearchFilterBar(
                searchText: $searchText,
                downloadFilter: $downloadFilter,
                isLoading: false,
                onRefresh: {}
            )
            .padding()
            .frame(width: 500)
        }
    }

    return PreviewWrapper()
}
