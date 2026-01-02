//
//  ModelSearchFilterBar.swift
//  WhisperPad
//

import SwiftUI

/// Model search and filter bar
///
/// Component for searching and filtering the model list.
struct ModelSearchFilterBar: View {
    @Binding var searchText: String
    @Binding var downloadFilter: ModelDownloadFilter
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            searchField

            // Status filter
            statusFilterPicker
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))

            TextField(L10n.get(.modelSearchPlaceholder), text: $searchText)
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
                .help(L10n.get(.modelSearchClear))
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
            Text(L10n.get(.modelSearchStatus))
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: $downloadFilter) {
                ForEach(ModelDownloadFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
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
                downloadFilter: $downloadFilter
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
                downloadFilter: $downloadFilter
            )
            .padding()
            .frame(width: 500)
        }
    }

    return PreviewWrapper()
}
