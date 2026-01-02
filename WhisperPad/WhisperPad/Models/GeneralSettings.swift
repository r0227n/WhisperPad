//
//  GeneralSettings.swift
//  WhisperPad
//

import Foundation

/// General settings
///
/// Manages basic application behavior settings.
struct GeneralSettings: Equatable, Sendable {
    /// Whether to launch at login
    var launchAtLogin: Bool = false

    /// Whether to show notification when transcription completes
    var showNotificationOnComplete: Bool = true

    /// Whether to play sound when transcription completes
    var playSoundOnComplete: Bool = true

    /// Menu bar icon custom settings
    var menuBarIconSettings: MenuBarIconSettings = .default

    /// Notification title
    var notificationTitle: String = "WhisperPad"

    /// Message when regular transcription completes
    var transcriptionCompleteMessage: String = "Transcription completed"

    /// Message when streaming transcription completes
    var streamingCompleteMessage: String = "Streaming transcription completed"

    /// Application display language
    var appLanguage: AppLanguage = .english

    /// Default settings
    static let `default` = GeneralSettings()
}

// MARK: - Codable

extension GeneralSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case showNotificationOnComplete
        case playSoundOnComplete
        case menuBarIconSettings
        case notificationTitle
        case transcriptionCompleteMessage
        case streamingCompleteMessage
        case appLanguage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showNotificationOnComplete = try container.decodeIfPresent(
            Bool.self, forKey: .showNotificationOnComplete
        ) ?? true
        playSoundOnComplete = try container.decodeIfPresent(Bool.self, forKey: .playSoundOnComplete) ?? true
        menuBarIconSettings = try container.decodeIfPresent(
            MenuBarIconSettings.self, forKey: .menuBarIconSettings
        ) ?? .default
        notificationTitle = try container.decodeIfPresent(String.self, forKey: .notificationTitle) ?? "WhisperPad"
        transcriptionCompleteMessage = try container.decodeIfPresent(
            String.self, forKey: .transcriptionCompleteMessage
        ) ?? "Transcription completed"
        streamingCompleteMessage = try container.decodeIfPresent(
            String.self, forKey: .streamingCompleteMessage
        ) ?? "Streaming transcription completed"
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .english
    }
}
