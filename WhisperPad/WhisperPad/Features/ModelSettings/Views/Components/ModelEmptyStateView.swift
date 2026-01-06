//
//  ModelEmptyStateView.swift
//  WhisperPad
//

import SwiftUI

/// Model Empty State View
///
/// Displays an empty state when no models match the current filter criteria.
struct ModelEmptyStateView: View {
    /// Action to reset the filters
    var onResetFilters: () -> Void
    /// ローカライズ設定
    let appLocale: AppLocale

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(appLocale.localized("model.list.no_results"))
                .foregroundStyle(.secondary)
            Button(appLocale.localized("model.filter.reset")) {
                onResetFilters()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    ModelEmptyStateView(onResetFilters: {}, appLocale: .system)
        .padding()
}
