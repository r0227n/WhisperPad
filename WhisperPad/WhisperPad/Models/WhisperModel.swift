//
//  WhisperModel.swift
//  WhisperPad
//

import Foundation

/// Whisper モデル情報
///
/// WhisperKit で使用可能なモデルの情報を表します。
struct WhisperModel: Equatable, Identifiable, Sendable {
    /// モデル ID（例: "openai_whisper-tiny"）
    let id: String

    /// 表示名
    var displayName: String {
        // "openai_whisper-tiny" -> "tiny"
        id.replacingOccurrences(of: "openai_whisper-", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }

    /// ダウンロード済みかどうか
    var isDownloaded: Bool

    /// 推奨モデルかどうか
    var isRecommended: Bool
}

extension WhisperModel {
    /// モデル ID からモデル情報を作成
    /// - Parameters:
    ///   - id: モデル ID
    ///   - isDownloaded: ダウンロード済みかどうか
    ///   - isRecommended: 推奨モデルかどうか
    /// - Returns: WhisperModel インスタンス
    static func from(
        id: String,
        isDownloaded: Bool = false,
        isRecommended: Bool = false
    ) -> WhisperModel {
        WhisperModel(
            id: id,
            isDownloaded: isDownloaded,
            isRecommended: isRecommended
        )
    }
}
