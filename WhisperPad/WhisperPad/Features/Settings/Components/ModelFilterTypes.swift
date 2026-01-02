//
//  ModelFilterTypes.swift
//  WhisperPad
//

import Foundation

/// Model download status filter
enum ModelDownloadFilter: String, CaseIterable, Sendable {
    case all
    case downloaded
    case notDownloaded

    @MainActor
    var displayName: String {
        switch self {
        case .all: L10n.get(.modelFilterAll)
        case .downloaded: L10n.get(.modelFilterDownloaded)
        case .notDownloaded: L10n.get(.modelFilterNotDownloaded)
        }
    }

    /// Determine if model matches this filter
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
