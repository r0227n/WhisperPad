//
//  AppSettings.swift
//  WhisperPad
//

import Foundation

/// アプリケーション設定
///
/// アプリケーション全体の設定を統合管理します。
struct AppSettings: Codable, Equatable, Sendable {
    /// 一般設定
    var general: GeneralSettings

    /// ホットキー設定
    var hotKey: HotKeySettings

    /// 録音設定
    var recording: RecordingSettings

    /// 文字起こし設定
    var transcription: TranscriptionSettings

    /// 出力設定
    var output: FileOutputSettings

    /// デフォルト設定
    static let `default` = AppSettings(
        general: .default,
        hotKey: .default,
        recording: .default,
        transcription: .default,
        output: .default
    )

    /// デフォルト初期化
    init(
        general: GeneralSettings = .default,
        hotKey: HotKeySettings = .default,
        recording: RecordingSettings = .default,
        transcription: TranscriptionSettings = .default,
        output: FileOutputSettings = .default
    ) {
        self.general = general
        self.hotKey = hotKey
        self.recording = recording
        self.transcription = transcription
        self.output = output
    }
}

// MARK: - UserDefaults Keys

extension AppSettings {
    /// UserDefaults で使用するキー
    enum Keys {
        static let settings = "WhisperPad.settings"
        static let storageBookmark = "WhisperPad.storageBookmark"
    }
}
