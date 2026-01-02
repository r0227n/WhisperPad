//
//  ModelFilterTypes.swift
//  WhisperPad
//

import Foundation

/// モデルダウンロード状態フィルター
enum ModelDownloadFilter: String, CaseIterable, Sendable {
    case all
    case downloaded
    case notDownloaded

    var displayName: String {
        switch self {
        case .all: "すべて"
        case .downloaded: "ダウンロード済み"
        case .notDownloaded: "未ダウンロード"
        }
    }

    /// モデルがこのフィルターに一致するか判定
    func matches(isDownloaded: Bool) -> Bool {
        switch self {
        case .all:
            true
        case .downloaded:
            isDownloaded
        case .notDownloaded:
            !isDownloaded
        }
    }
}
