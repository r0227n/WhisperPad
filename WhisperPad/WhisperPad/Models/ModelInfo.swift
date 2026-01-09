//
//  ModelInfo.swift
//  WhisperPad
//

import Foundation

/// モデル情報
struct ModelInfo: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let variant: String
    let sizeDescription: String
    var isDownloaded: Bool
    var isRecommended: Bool

    init(
        name: String,
        variant: String,
        sizeDescription: String,
        isDownloaded: Bool = false,
        isRecommended: Bool = false
    ) {
        self.id = name
        self.name = name
        self.variant = variant
        self.sizeDescription = sizeDescription
        self.isDownloaded = isDownloaded
        self.isRecommended = isRecommended
    }
}
