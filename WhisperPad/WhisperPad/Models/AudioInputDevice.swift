//
//  AudioInputDevice.swift
//  WhisperPad
//

import Foundation

/// 音声入力デバイス
///
/// 利用可能な音声入力デバイス（マイク）を表すモデルです。
struct AudioInputDevice: Identifiable, Equatable, Sendable {
    /// デバイス ID
    let id: String

    /// デバイス名
    let name: String

    /// システムデフォルトデバイスかどうか
    let isDefault: Bool

    /// システムデフォルトデバイス（プレースホルダー）
    ///
    /// id が空文字列の場合、システムデフォルトのマイクを使用します。
    static let systemDefault = AudioInputDevice(
        id: "",
        name: "システムデフォルト",
        isDefault: true
    )
}
