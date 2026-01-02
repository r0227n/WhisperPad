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

    /// キャンセル時のアイコン設定
    var cancel: StatusIconConfig

    /// デフォルト設定
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
    case cancel = "キャンセル"

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
        case .cancel: "xmark.circle"
        }
    }

    /// 状態の詳細説明（設定画面の右パネル表示用）
    var detailedDescription: String {
        switch self {
        case .idle:
            "アプリが起動していて、録音や文字起こしを行っていない待機状態です。ショートカットキーを押すといつでも録音を開始できます。"
        case .recording:
            "音声を録音している状態です。マイクから入力される音声がリアルタイムで記録されています。録音を停止すると文字起こし処理が始まります。"
        case .paused:
            "録音を一時停止している状態です。録音を再開するか、停止して文字起こしを開始できます。"
        case .transcribing:
            "録音した音声データをWhisperモデルで文字起こししている状態です。処理にはデバイスの性能やモデルサイズに応じて時間がかかります。"
        case .completed:
            "文字起こしが正常に完了した状態です。結果はクリップボードにコピーされ、設定に応じてファイルにも保存されます。"
        case .streamingTranscribing:
            "ストリーミングモードで録音と文字起こしを同時に行っている状態です。話しながらリアルタイムで文字起こし結果が表示されます。"
        case .streamingCompleted:
            "ストリーミング文字起こしが正常に完了した状態です。リアルタイム処理された結果がクリップボードにコピーされます。"
        case .error:
            "録音または文字起こし中にエラーが発生した状態です。マイクへのアクセス権限やモデルのダウンロード状態を確認してください。"
        case .cancel:
            "録音または文字起こしがユーザーによってキャンセルされた状態です。録音データは破棄され、文字起こしは行われません。"
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
        case .cancel: cancel
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
        case .cancel: cancel = config
        }
    }
}
