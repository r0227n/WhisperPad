//
//  MenuBarIconSettings.swift
//  WhisperPad
//

import AppKit
import Foundation
import SwiftUI

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

    /// エラー時のアイコン設定
    var error: StatusIconConfig

    /// キャンセル時のアイコン設定
    var cancel: StatusIconConfig

    /// モデル読み込み中のアイコン設定
    var loading: StatusIconConfig

    /// デフォルト設定
    static let `default` = MenuBarIconSettings(
        idle: StatusIconConfig(symbolName: "mic", color: .systemGray),
        recording: StatusIconConfig(symbolName: "mic.fill", color: .systemRed),
        paused: StatusIconConfig(symbolName: "pause.fill", color: .systemOrange),
        transcribing: StatusIconConfig(symbolName: "gear", color: .systemBlue),
        completed: StatusIconConfig(symbolName: "checkmark.circle", color: .systemGreen),
        error: StatusIconConfig(symbolName: "exclamationmark.triangle", color: .systemYellow),
        cancel: StatusIconConfig(symbolName: "xmark.circle", color: .systemGray),
        loading: StatusIconConfig(symbolName: "arrow.triangle.2.circlepath", color: .systemBlue)
    )
}

// MARK: - IconConfigStatus

/// 編集対象の状態タイプ
///
/// 設定画面で表示するための状態識別子です。
enum IconConfigStatus: String, CaseIterable, Sendable, Identifiable {
    case idle
    case recording
    case paused
    case transcribing
    case completed
    case error
    case cancel
    case loading

    var id: String { rawValue }

    /// 表示名（ローカライズ済み）
    var displayName: String {
        String(localized: String.LocalizationValue(localizedKey))
    }

    /// 対応する AppStatus のシンボル名（デフォルト）
    var defaultSymbolName: String {
        switch self {
        case .idle: "mic"
        case .recording: "mic.fill"
        case .paused: "pause.fill"
        case .transcribing: "gear"
        case .completed: "checkmark.circle"
        case .error: "exclamationmark.triangle"
        case .cancel: "xmark.circle"
        case .loading: "arrow.triangle.2.circlepath"
        }
    }

    /// 状態の詳細説明（設定画面の右パネル表示用）
    var detailedDescription: String {
        String(localized: String.LocalizationValue(descriptionKey))
    }

    /// ローカライズキー
    var localizedKey: String {
        switch self {
        case .idle: "icon.status.idle"
        case .recording: "icon.status.recording"
        case .paused: "icon.status.paused"
        case .transcribing: "icon.status.transcribing"
        case .completed: "icon.status.completed"
        case .error: "icon.status.error"
        case .cancel: "icon.status.cancel"
        case .loading: "icon.status.loading"
        }
    }

    /// 説明のローカライズキー
    var descriptionKey: String {
        switch self {
        case .idle: "icon.description.idle"
        case .recording: "icon.description.recording"
        case .paused: "icon.description.paused"
        case .transcribing: "icon.description.transcribing"
        case .completed: "icon.description.completed"
        case .error: "icon.description.error"
        case .cancel: "icon.description.cancel"
        case .loading: "icon.description.loading"
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
        case .error: error
        case .cancel: cancel
        case .loading: loading
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
        case .error: error = config
        case .cancel: cancel = config
        case .loading: loading = config
        }
    }
}
