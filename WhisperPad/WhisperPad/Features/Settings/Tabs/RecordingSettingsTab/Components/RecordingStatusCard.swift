//
//  RecordingStatusCard.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 録音状態カード
///
/// 現在の録音状態と最後の録音情報を表示するカードコンポーネント。
/// RecordingFeature.Status と連携して状態を視覚化します。
struct RecordingStatusCard: View {
    /// 現在の録音ステータス
    let status: RecordingStatus
    /// 最後の録音時間（オプション）
    let lastRecordingTime: Date?
    /// 最後の録音の長さ（オプション）
    let lastDuration: TimeInterval?

    var body: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 12) {
                // ステータス表示
                HStack(spacing: 12) {
                    StatusBadge(
                        status: status.badgeStatus,
                        shouldPulse: status.shouldPulse
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status: \(status.displayName)")
                            .font(.headline)

                        if let duration = status.currentDuration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // 最後の録音情報
                if lastRecordingTime != nil || lastDuration != nil {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        if let time = lastRecordingTime {
                            HStack {
                                Text("Last Recording:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatRelativeTime(time))
                            }
                            .font(.subheadline)
                        }

                        if let duration = lastDuration {
                            HStack {
                                Text("Duration:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDuration(duration))
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recording status: \(status.displayName)")
    }

    // MARK: - Private Methods

    /// 経過時間をフォーマット（MM:SS）
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 相対時間をフォーマット（「2 minutes ago」など）
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Recording Status

/// 録音状態
enum RecordingStatus: Equatable {
    /// 待機中
    case idle
    /// 準備中
    case preparing
    /// 録音中
    case recording(duration: TimeInterval)
    /// 一時停止中
    case paused(duration: TimeInterval)
    /// 処理中
    case processing

    /// 表示名
    var displayName: String {
        switch self {
        case .idle:
            "Ready"
        case .preparing:
            "Preparing..."
        case .recording:
            "Recording"
        case .paused:
            "Paused"
        case .processing:
            "Processing"
        }
    }

    /// StatusBadge の状態
    var badgeStatus: StatusBadge.Status {
        switch self {
        case .idle:
            .ready
        case .preparing:
            .processing
        case .recording:
            .recording
        case .paused:
            .paused
        case .processing:
            .processing
        }
    }

    /// パルスアニメーションの有無
    var shouldPulse: Bool {
        switch self {
        case .recording, .processing:
            true
        default:
            false
        }
    }

    /// 現在の経過時間
    var currentDuration: TimeInterval? {
        switch self {
        case let .recording(duration), let .paused(duration):
            duration
        default:
            nil
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    RecordingStatusCard(
        status: .idle,
        lastRecordingTime: Date().addingTimeInterval(-120),
        lastDuration: 45
    )
    .padding()
    .frame(width: 400)
}

#Preview("Recording") {
    RecordingStatusCard(
        status: .recording(duration: 32),
        lastRecordingTime: nil,
        lastDuration: nil
    )
    .padding()
    .frame(width: 400)
}

#Preview("Paused") {
    RecordingStatusCard(
        status: .paused(duration: 45),
        lastRecordingTime: nil,
        lastDuration: nil
    )
    .padding()
    .frame(width: 400)
}

#Preview("Processing") {
    RecordingStatusCard(
        status: .processing,
        lastRecordingTime: nil,
        lastDuration: nil
    )
    .padding()
    .frame(width: 400)
}

#Preview("All States") {
    ScrollView {
        VStack(spacing: 16) {
            RecordingStatusCard(
                status: .idle,
                lastRecordingTime: Date().addingTimeInterval(-300),
                lastDuration: 120
            )

            RecordingStatusCard(
                status: .preparing,
                lastRecordingTime: nil,
                lastDuration: nil
            )

            RecordingStatusCard(
                status: .recording(duration: 15),
                lastRecordingTime: nil,
                lastDuration: nil
            )

            RecordingStatusCard(
                status: .paused(duration: 30),
                lastRecordingTime: nil,
                lastDuration: nil
            )

            RecordingStatusCard(
                status: .processing,
                lastRecordingTime: nil,
                lastDuration: nil
            )
        }
        .padding()
    }
    .frame(width: 400, height: 600)
}
