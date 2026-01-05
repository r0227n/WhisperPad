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
    var onReset: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("model.list.no_results")
                .foregroundStyle(.secondary)
            Button("model.filter.reset") {
                onReset()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    ModelEmptyStateView(onReset: {})
        .padding()
}
