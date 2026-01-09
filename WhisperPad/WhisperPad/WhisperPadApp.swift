//
//  WhisperPadApp.swift
//  WhisperPad
//

import SwiftUI

/// WhisperPad アプリケーションのエントリーポイント
///
/// メニューバー常駐アプリとして動作し、`AppDelegate` を使用して
/// ステータスアイテムとメニューを管理します。
/// 設定画面は AppDelegate で NSHostingController を使用して開きます。
@main
struct WhisperPadApp: App {
    // MARK: - Properties

    /// AppKit の AppDelegate をブリッジするアダプター
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        // メニューバーアプリのため、表示するシーンはありません
        // 設定画面は AppDelegate.openSettings() で NSHostingController を使用して開きます
        Settings {
            EmptyView()
        }
    }
}
