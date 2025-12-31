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

    /// モデルサイズ（バイト）
    let sizeBytes: Int64

    /// ダウンロード済みかどうか
    var isDownloaded: Bool

    /// 推奨モデルかどうか
    var isRecommended: Bool

    /// サイズの表示用文字列
    var sizeDisplayString: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

// MARK: - Model Presets

/// モデル情報を保持する構造体
struct WhisperModelInfo: Sendable {
    let size: Int64
    let speed: Int
    let accuracy: Int
}

extension WhisperModel {
    /// 既知のモデル情報
    static let knownModels: [String: WhisperModelInfo] = [
        "openai_whisper-tiny": WhisperModelInfo(size: 75_000_000, speed: 5, accuracy: 2),
        "openai_whisper-tiny.en": WhisperModelInfo(size: 75_000_000, speed: 5, accuracy: 2),
        "openai_whisper-base": WhisperModelInfo(size: 145_000_000, speed: 4, accuracy: 3),
        "openai_whisper-base.en": WhisperModelInfo(size: 145_000_000, speed: 4, accuracy: 3),
        "openai_whisper-small": WhisperModelInfo(size: 488_000_000, speed: 3, accuracy: 4),
        "openai_whisper-small.en": WhisperModelInfo(size: 488_000_000, speed: 3, accuracy: 4),
        "openai_whisper-medium": WhisperModelInfo(size: 1_530_000_000, speed: 2, accuracy: 4),
        "openai_whisper-medium.en": WhisperModelInfo(size: 1_530_000_000, speed: 2, accuracy: 4),
        "openai_whisper-large-v2": WhisperModelInfo(size: 3_090_000_000, speed: 1, accuracy: 5),
        "openai_whisper-large-v3": WhisperModelInfo(size: 3_090_000_000, speed: 1, accuracy: 5),
        "openai_whisper-large-v3-turbo": WhisperModelInfo(size: 1_620_000_000, speed: 2, accuracy: 5)
    ]

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
        let info = knownModels[id]
        return WhisperModel(
            id: id,
            sizeBytes: info?.size ?? 0,
            isDownloaded: isDownloaded,
            isRecommended: isRecommended
        )
    }

    /// 速度評価（1-5）
    var speedRating: Int {
        Self.knownModels[id]?.speed ?? 3
    }

    /// 精度評価（1-5）
    var accuracyRating: Int {
        Self.knownModels[id]?.accuracy ?? 3
    }

    /// 速度評価の表示文字列
    var speedDisplayString: String {
        String(repeating: "⚡", count: speedRating)
    }

    /// 精度評価の表示文字列
    var accuracyDisplayString: String {
        String(repeating: "★", count: accuracyRating) +
            String(repeating: "☆", count: 5 - accuracyRating)
    }
}
