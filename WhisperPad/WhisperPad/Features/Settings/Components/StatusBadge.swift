//
//  StatusBadge.swift
//  WhisperPad
//

import SwiftUI

/// ステータスバッジ
///
/// 色付きのステータスインジケーターを表示するコンポーネント。
/// 録音状態（Ready/Recording/Paused/Processing）を視覚的に示します。
struct StatusBadge: View {
    /// ステータスの種類
    let status: Status
    /// パルスアニメーションの有無
    let shouldPulse: Bool
    /// バッジのサイズ
    let size: CGFloat

    init(
        status: Status,
        shouldPulse: Bool = false,
        size: CGFloat = 12
    ) {
        self.status = status
        self.shouldPulse = shouldPulse
        self.size = size
    }

    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .overlay {
                if shouldPulse {
                    Circle()
                        .stroke(status.color, lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.5 : 1)
                        .opacity(isPulsing ? 0 : 1)
                }
            }
            .onAppear {
                if shouldPulse {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: shouldPulse) { _, newValue in
                if !newValue {
                    isPulsing = false
                }
            }
            .accessibilityLabel(status.accessibilityLabel)
    }

    // MARK: - Status Type

    /// ステータスの種類
    enum Status {
        /// 待機中
        case ready
        /// 録音中
        case recording
        /// 一時停止中
        case paused
        /// 処理中
        case processing
        /// エラー
        case error

        /// ステータスの色
        var color: Color {
            switch self {
            case .ready:
                .green
            case .recording:
                .red
            case .paused:
                .yellow
            case .processing:
                .blue
            case .error:
                .red
            }
        }

        /// アクセシビリティラベル
        var accessibilityLabel: String {
            switch self {
            case .ready:
                "Ready"
            case .recording:
                "Recording"
            case .paused:
                "Paused"
            case .processing:
                "Processing"
            case .error:
                "Error"
            }
        }
    }
}

// MARK: - Preview

#Preview("All Status") {
    VStack(alignment: .leading, spacing: 20) {
        Text("Status Badge Examples")
            .font(.headline)

        // 各ステータス
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                StatusBadge(status: .ready)
                Text("Ready")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .recording)
                Text("Recording")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .paused)
                Text("Paused")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .processing)
                Text("Processing")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .error)
                Text("Error")
                    .font(.caption)
            }
        }

        Divider()

        // パルスアニメーション
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                StatusBadge(status: .recording, shouldPulse: true)
                Text("Recording (Pulsing)")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .processing, shouldPulse: true)
                Text("Processing (Pulsing)")
                    .font(.caption)
            }
        }

        Divider()

        // 様々なサイズ
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                StatusBadge(status: .recording, size: 8)
                Text("Small")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .recording, size: 12)
                Text("Medium")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .recording, size: 16)
                Text("Large")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                StatusBadge(status: .recording, size: 20)
                Text("Extra Large")
                    .font(.caption)
            }
        }
    }
    .padding()
    .frame(width: 500)
}

#Preview("In Use") {
    VStack(alignment: .leading, spacing: 12) {
        // ステータスカードの例
        HStack(spacing: 12) {
            StatusBadge(status: .ready)
            VStack(alignment: .leading, spacing: 2) {
                Text("Status: Ready")
                    .font(.headline)
                Text("Ready to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)

        HStack(spacing: 12) {
            StatusBadge(status: .recording, shouldPulse: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Status: Recording")
                    .font(.headline)
                Text("00:45 elapsed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
    .frame(width: 300)
}
