//
//  ModelFilterTypes.swift
//  WhisperPad
//

import Foundation
import SwiftUI

/// モデルダウンロード状態フィルター
enum ModelDownloadFilter: String, CaseIterable, Sendable {
    case all
    case downloaded
    case notDownloaded

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

    /// ローカライズキー
    var localizedKey: LocalizedStringKey {
        switch self {
        case .all: "model.filter.all"
        case .downloaded: "model.row.downloaded"
        case .notDownloaded: "model.row.not_downloaded"
        }
    }

    /// ローカライズキー（String）
    var localizationKey: String {
        switch self {
        case .all: "model.filter.all"
        case .downloaded: "model.row.downloaded"
        case .notDownloaded: "model.row.not_downloaded"
        }
    }
}
