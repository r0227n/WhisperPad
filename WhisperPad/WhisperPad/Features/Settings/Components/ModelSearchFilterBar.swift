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
    let appLocale: AppLocale

    var body: some View {
        HStack(spacing: 12) {
            // 検索フィールド
            searchField

            // 状態フィルター
            statusFilterPicker
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))

            TextField(appLocale.localized("model.search.placeholder"), text: $searchText)
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
                .help(appLocale.localized("model.search.clear"))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Status Filter Picker

    private var statusFilterPicker: some View {
        HStack(spacing: 4) {
            Text(appLocale.localized("model.filter.status"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: $downloadFilter) {
                ForEach(ModelDownloadFilter.allCases, id: \.self) { filter in
                    Text(appLocale.localized(String.LocalizationValue(filter.localizationKey)))
                        .tag(filter)
                }
            }
            .pickerStyle(.menu)
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
                appLocale: .system
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
                appLocale: .system
            )
            .padding()
            .frame(width: 500)
        }
    }

    return PreviewWrapper()
}
