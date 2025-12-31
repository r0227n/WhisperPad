//
//  StreamingSettings.swift
//  WhisperPad
//

import Foundation

/// ストリーミング文字起こし設定
///
/// リアルタイム音声認識の動作パラメータを管理します。
struct StreamingSettings: Codable, Equatable, Sendable {
    /// 使用するモデル名
    ///
    /// `nil` の場合はデフォルトモデルを使用します。
    var modelName: String?

    /// 文字起こし間隔（秒）
    ///
    /// 音声バッファを処理する間隔を指定します。
    var transcriptionInterval: Double

    /// 確定に必要な連続回数
    ///
    /// 同じテキストがこの回数連続で出力されると確定テキストになります。
    var confirmationCount: Int

    /// 無音判定しきい値
    ///
    /// この値以下の音量を無音として判定します（0.0〜1.0）。
    var silenceThreshold: Float

    /// デコード中プレビューを表示するかどうか
    var showDecodingPreview: Bool

    /// 認識言語
    ///
    /// `nil` の場合は自動検出を使用します。
    var language: String?

    /// デフォルト設定
    static let `default` = StreamingSettings()

    /// デフォルト初期化
    init(
        modelName: String? = nil,
        transcriptionInterval: Double = 1.0,
        confirmationCount: Int = 2,
        silenceThreshold: Float = 0.3,
        showDecodingPreview: Bool = true,
        language: String? = "ja"
    ) {
        self.modelName = modelName
        self.transcriptionInterval = transcriptionInterval
        self.confirmationCount = confirmationCount
        self.silenceThreshold = silenceThreshold
        self.showDecodingPreview = showDecodingPreview
        self.language = language
    }
}
