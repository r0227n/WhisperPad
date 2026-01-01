//
//  MenuBarIconSettings.swift
//  WhisperPad
//

import AppKit
import Foundation

/// 各状態のアイコン設定
///
/// メニューバーに表示するSF Symbolと色を管理します。
struct StatusIconConfig: Codable, Equatable, Sendable {
    /// SF Symbol 名
    var symbolName: String

    /// 色のデータ (NSColor を Data に変換して保存)
    var colorData: Data

    /// NSColor を取得・設定
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

    /// イニシャライザ
    /// - Parameters:
    ///   - symbolName: SF Symbol 名
    ///   - color: アイコンの色
    init(symbolName: String, color: NSColor) {
        self.symbolName = symbolName
        self.colorData = (try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )) ?? Data()
    }
}

/// メニューバーアイコン設定
///
/// 各アプリ状態ごとのアイコンと色を管理します。
struct MenuBarIconSettings: Codable, Equatable, Sendable {
    /// 待機中のアイコン設定
    var idle: StatusIconConfig

    /// 録音中のアイコン設定
    var recording: StatusIconConfig

    /// 一時停止中のアイコン設定
    var paused: StatusIconConfig

    /// 文字起こし中のアイコン設定
    var transcribing: StatusIconConfig

    /// 完了時のアイコン設定
    var completed: StatusIconConfig

    /// ストリーミング文字起こし中のアイコン設定
    var streamingTranscribing: StatusIconConfig

    /// ストリーミング完了時のアイコン設定
    var streamingCompleted: StatusIconConfig

    /// エラー時のアイコン設定
    var error: StatusIconConfig

    /// デフォルト設定
    static let `default` = MenuBarIconSettings(
        idle: StatusIconConfig(symbolName: "mic", color: .systemGray),
        recording: StatusIconConfig(symbolName: "mic.fill", color: .systemRed),
        paused: StatusIconConfig(symbolName: "pause.fill", color: .systemOrange),
        transcribing: StatusIconConfig(symbolName: "gear", color: .systemBlue),
        completed: StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen),
        streamingTranscribing: StatusIconConfig(symbolName: "waveform.badge.mic", color: .systemPurple),
        streamingCompleted: StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen),
        error: StatusIconConfig(symbolName: "exclamationmark.triangle", color: .systemYellow)
    )
}

// MARK: - IconConfigStatus

/// 編集対象の状態タイプ
///
/// 設定画面で表示するための状態識別子です。
enum IconConfigStatus: String, CaseIterable, Sendable, Identifiable {
    case idle = "待機中"
    case recording = "録音中"
    case paused = "一時停止中"
    case transcribing = "文字起こし中"
    case completed = "完了"
    case streamingTranscribing = "ストリーミング中"
    case streamingCompleted = "ストリーミング完了"
    case error = "エラー"

    var id: String { rawValue }

    /// 対応する AppStatus のシンボル名（デフォルト）
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
        }
    }
}

// MARK: - MenuBarIconSettings Extension

extension MenuBarIconSettings {
    /// 状態に対応する設定を取得
    /// - Parameter status: 状態タイプ
    /// - Returns: 対応するアイコン設定
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
        }
    }

    /// 状態に対応する設定を更新
    /// - Parameters:
    ///   - config: 新しいアイコン設定
    ///   - status: 状態タイプ
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
        }
    }
}
