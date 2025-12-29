//
//  WhisperPadApp.swift
//  WhisperPad
//
//  Created by RyoNishimura on 2025/12/27.
//

import SwiftUI

/// WhisperPad アプリケーションのエントリーポイント
///
/// メニューバー常駐アプリとして動作し、`AppDelegate` を使用して
/// ステータスアイテムとメニューを管理します。
@main
struct WhisperPadApp: App {
    // MARK: - Properties

    /// AppKit の AppDelegate をブリッジするアダプター
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        // メニューバーアプリのため、WindowGroup は使用しない
        // Settings シーンは Phase 5 で追加予定
        Settings {
            EmptyView()
        }
    }
}
