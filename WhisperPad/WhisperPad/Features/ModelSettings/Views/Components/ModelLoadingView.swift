//
//  ModelLoadingView.swift
//  WhisperPad
//

import SwiftUI

/// Model Loading View
///
/// Displays a loading indicator while models are being fetched.
struct ModelLoadingView: View {
    /// ローカライズ設定
    let appLocale: AppLocale

    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text(appLocale.localized("model.list.loading"))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    ModelLoadingView(appLocale: .system)
        .padding()
}
