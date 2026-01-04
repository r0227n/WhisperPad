//
//  WhisperPadApp.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// 設定画面を開くための通知名
extension Notification.Name {
    static let openSettingsRequest = Notification.Name("openSettingsRequest")
    static let settingsWindowClosed = Notification.Name("settingsWindowClosed")
}

/// Settings シーンを開くための隠しウィンドウビュー
///
/// macOS 14+ では `SettingsLink` または `@Environment(\.openSettings)` を使用する必要があるため、
/// SwiftUI コンテキスト内でこの環境変数にアクセスするための隠しウィンドウを提供します。
private struct HiddenWindowView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequest)) { _ in
                Task { @MainActor in
                    // アクティベーションポリシーを regular に変更してウィンドウを表示可能にする
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(100))
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    try? await Task.sleep(for: .milliseconds(200))
                    // 設定ウィンドウを前面に持ってくる
                    if let settingsWindow = NSApp.windows.first(where: {
                        $0.title.contains("設定") || $0.title.contains("Settings")
                    }) {
                        settingsWindow.makeKeyAndOrderFront(nil)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .settingsWindowClosed)) { _ in
                // 設定ウィンドウが閉じられたらアクティベーションポリシーを accessory に戻す
                NSApp.setActivationPolicy(.accessory)
            }
    }
}

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
        // Settings シーンを開くための隠しウィンドウ（Settings より先に宣言する必要がある）
        Window("Hidden", id: "HiddenWindow") {
            HiddenWindowView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)

        // 設定画面
        Settings {
            SettingsView(
                store: appDelegate.store.scope(
                    state: \.settings,
                    action: \.settings
                )
            )
            .onDisappear {
                NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
            }
        }
    }
}
