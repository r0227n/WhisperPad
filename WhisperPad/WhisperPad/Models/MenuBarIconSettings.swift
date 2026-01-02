//
//  MenuBarIconSettings.swift
//  WhisperPad
//

import AppKit
import Foundation

/// Icon configuration for each status
///
/// Manages SF Symbol and color displayed in menu bar.
struct StatusIconConfig: Codable, Equatable, Sendable {
    /// SF Symbol name
    var symbolName: String

    /// Color data (NSColor converted to Data for storage)
    var colorData: Data

    /// Get/set NSColor
    var color: NSColor {
        get {
            guard let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self,
                from: colorData
            ) else {
                return .systemGray
            }
            return color
        }
        set {
            colorData = (try? NSKeyedArchiver.archivedData(
                withRootObject: newValue,
                requiringSecureCoding: true
            )) ?? Data()
        }
    }

    /// Initializer
    /// - Parameters:
    ///   - symbolName: SF Symbol name
    ///   - color: Icon color
    init(symbolName: String, color: NSColor) {
        self.symbolName = symbolName
        self.colorData = (try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )) ?? Data()
    }
}

/// Menu bar icon settings
///
/// Manages icons and colors for each app state.
struct MenuBarIconSettings: Codable, Equatable, Sendable {
    /// Idle icon configuration
    var idle: StatusIconConfig

    /// Recording icon configuration
    var recording: StatusIconConfig

    /// Paused icon configuration
    var paused: StatusIconConfig

    /// Transcribing icon configuration
    var transcribing: StatusIconConfig

    /// Completed icon configuration
    var completed: StatusIconConfig

    /// Streaming transcribing icon configuration
    var streamingTranscribing: StatusIconConfig

    /// Streaming completed icon configuration
    var streamingCompleted: StatusIconConfig

    /// Error icon configuration
    var error: StatusIconConfig

    /// Cancel icon configuration
    var cancel: StatusIconConfig

    /// Default settings
    static let `default` = MenuBarIconSettings(
        idle: StatusIconConfig(symbolName: "mic", color: .systemGray),
        recording: StatusIconConfig(symbolName: "mic.fill", color: .systemRed),
        paused: StatusIconConfig(symbolName: "pause.fill", color: .systemOrange),
        transcribing: StatusIconConfig(symbolName: "gear", color: .systemBlue),
        completed: StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen),
        streamingTranscribing: StatusIconConfig(symbolName: "waveform.badge.mic", color: .systemPurple),
        streamingCompleted: StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen),
        error: StatusIconConfig(symbolName: "exclamationmark.triangle", color: .systemYellow),
        cancel: StatusIconConfig(symbolName: "xmark.circle", color: .systemGray)
    )
}

// MARK: - IconConfigStatus

/// Status type for editing
///
/// Status identifier for display in settings screen.
enum IconConfigStatus: String, CaseIterable, Sendable, Identifiable {
    case idle
    case recording
    case paused
    case transcribing
    case completed
    case streamingTranscribing
    case streamingCompleted
    case error
    case cancel

    var id: String { rawValue }

    /// Localized display name
    @MainActor
    var displayName: String {
        switch self {
        case .idle: L10n.get(.iconStatusIdle)
        case .recording: L10n.get(.iconStatusRecording)
        case .paused: L10n.get(.iconStatusPaused)
        case .transcribing: L10n.get(.iconStatusTranscribing)
        case .completed: L10n.get(.iconStatusCompleted)
        case .streamingTranscribing: L10n.get(.iconStatusStreamingTranscribing)
        case .streamingCompleted: L10n.get(.iconStatusStreamingCompleted)
        case .error: L10n.get(.iconStatusError)
        case .cancel: L10n.get(.iconStatusCancel)
        }
    }

    /// Default symbol name for corresponding AppStatus
    var defaultSymbolName: String {
        switch self {
        case .idle: "mic"
        case .recording: "mic.fill"
        case .paused: "pause.fill"
        case .transcribing: "gear"
        case .completed: "checkmark.circle"
        case .streamingTranscribing: "waveform.badge.mic"
        case .streamingCompleted: "checkmark.circle"
        case .error: "exclamationmark.triangle"
        case .cancel: "xmark.circle"
        }
    }

    /// Localized detailed description for settings screen right panel
    @MainActor
    var detailedDescription: String {
        switch self {
        case .idle: L10n.get(.iconStatusIdleDescription)
        case .recording: L10n.get(.iconStatusRecordingDescription)
        case .paused: L10n.get(.iconStatusPausedDescription)
        case .transcribing: L10n.get(.iconStatusTranscribingDescription)
        case .completed: L10n.get(.iconStatusCompletedDescription)
        case .streamingTranscribing: L10n.get(.iconStatusStreamingTranscribingDescription)
        case .streamingCompleted: L10n.get(.iconStatusStreamingCompletedDescription)
        case .error: L10n.get(.iconStatusErrorDescription)
        case .cancel: L10n.get(.iconStatusCancelDescription)
        }
    }
}

// MARK: - MenuBarIconSettings Extension

extension MenuBarIconSettings {
    /// Get configuration for status
    /// - Parameter status: Status type
    /// - Returns: Corresponding icon configuration
    func config(for status: IconConfigStatus) -> StatusIconConfig {
        switch status {
        case .idle: idle
        case .recording: recording
        case .paused: paused
        case .transcribing: transcribing
        case .completed: completed
        case .streamingTranscribing: streamingTranscribing
        case .streamingCompleted: streamingCompleted
        case .error: error
        case .cancel: cancel
        }
    }

    /// Update configuration for status
    /// - Parameters:
    ///   - config: New icon configuration
    ///   - status: Status type
    mutating func setConfig(_ config: StatusIconConfig, for status: IconConfigStatus) {
        switch status {
        case .idle: idle = config
        case .recording: recording = config
        case .paused: paused = config
        case .transcribing: transcribing = config
        case .completed: completed = config
        case .streamingTranscribing: streamingTranscribing = config
        case .streamingCompleted: streamingCompleted = config
        case .error: error = config
        case .cancel: cancel = config
        }
    }
}
