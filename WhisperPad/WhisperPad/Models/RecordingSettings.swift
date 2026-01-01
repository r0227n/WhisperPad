//
//  RecordingSettings.swift
//  WhisperPad
//

import Foundation

/// 録音設定
///
/// 音声録音に関する設定を管理します。
struct RecordingSettings: Codable, Equatable, Sendable {
    /// 入力デバイス ID
    ///
    /// `nil` の場合はシステムデフォルトのデバイスを使用します。
    var inputDeviceID: String?

    /// 無音検出を有効にするかどうか
    var silenceDetectionEnabled: Bool

    /// 無音判定しきい値（dB）
    var silenceThreshold: Float

    /// 無音継続時間（秒）
    ///
    /// この時間無音が続くと録音を自動停止します。
    var silenceDuration: TimeInterval

    /// デフォルト設定
    static let `default` = RecordingSettings()

    /// デフォルト初期化
    init(
        inputDeviceID: String? = nil,
        silenceDetectionEnabled: Bool = false,
        silenceThreshold: Float = -40.0,
        silenceDuration: TimeInterval = 3.0
    ) {
        self.inputDeviceID = inputDeviceID
        self.silenceDetectionEnabled = silenceDetectionEnabled
        self.silenceThreshold = silenceThreshold
        self.silenceDuration = silenceDuration
    }
}
