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
        case .all:
            String(localized: "model.filter.all", comment: "All")
        case .downloaded:
            String(localized: "model.row.downloaded", comment: "Downloaded")
        case .notDownloaded:
            String(localized: "model.row.not_downloaded", comment: "Not Downloaded")
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
