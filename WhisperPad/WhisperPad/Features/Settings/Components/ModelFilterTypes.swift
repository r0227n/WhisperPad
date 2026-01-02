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
        case .all: "全て"
        case .downloaded: "済"
        case .notDownloaded: "未"
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
