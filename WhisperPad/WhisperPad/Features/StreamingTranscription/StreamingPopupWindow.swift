//
//  StreamingPopupWindow.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import SwiftUI

/// ストリーミング文字起こし用フローティングポップアップウィンドウ
final class StreamingPopupWindow: NSPanel {
    // MARK: - Constants

    private enum Constants {
        static let windowWidth: CGFloat = 400
        static let windowHeight: CGFloat = 300
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - Properties

    private let hostingView: NSHostingView<AnyView>
    private var visualEffectView: NSVisualEffectView?

    // MARK: - Initialization

    init(store: StoreOf<StreamingTranscriptionFeature>) {
        // SwiftUIビューをホスト
        let view = StreamingTranscriptionView(store: store)
        self.hostingView = NSHostingView(rootView: AnyView(view))

        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Constants.windowWidth,
                height: Constants.windowHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    // MARK: - Setup

    private func setupWindow() {
        // ウィンドウプロパティ
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // アニメーション
        animationBehavior = .utilityWindow
    }

    private func setupContent() {
        let windowFrame = NSRect(
            x: 0,
            y: 0,
            width: Constants.windowWidth,
            height: Constants.windowHeight
        )

        // ビジュアルエフェクトビュー（背景）
        let effectView = NSVisualEffectView(frame: windowFrame)
        effectView.material = NSVisualEffectView.Material.hudWindow
        effectView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        effectView.state = NSVisualEffectView.State.active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = Constants.cornerRadius
        effectView.layer?.masksToBounds = true
        self.visualEffectView = effectView

        // ホスティングビューを追加
        hostingView.frame = windowFrame
        hostingView.autoresizingMask = [.width, .height]

        // コンテンツビューを設定
        effectView.addSubview(hostingView)
        contentView = effectView
    }

    // MARK: - Positioning

    /// メニューバーアイコンの直下にウィンドウを表示
    /// - Parameter statusItem: メニューバーのステータスアイテム
    func showBelowMenuBarIcon(relativeTo statusItem: NSStatusItem) {
        guard let button = statusItem.button,
              let buttonWindow = button.window
        else {
            // フォールバック: 画面中央上部に表示
            positionAtScreenTopCenter()
            return
        }

        // ボタンのスクリーン座標を取得
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        // ウィンドウの位置を計算（ボタンの中央下）
        let windowOriginX = screenFrame.midX - Constants.windowWidth / 2
        let windowOriginY = screenFrame.minY - Constants.windowHeight - 4  // 4pxのマージン

        // 画面端からはみ出さないように調整
        let adjustedOriginX = adjustXPosition(windowOriginX)

        setFrameOrigin(NSPoint(x: adjustedOriginX, y: windowOriginY))
        makeKeyAndOrderFront(nil)
    }

    /// 画面の上部中央に表示（フォールバック用）
    private func positionAtScreenTopCenter() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let originX = screenFrame.midX - Constants.windowWidth / 2
        let originY = screenFrame.maxY - Constants.windowHeight - 50

        setFrameOrigin(NSPoint(x: originX, y: originY))
        makeKeyAndOrderFront(nil)
    }

    /// X座標を画面内に収まるよう調整
    private func adjustXPosition(_ coordinate: CGFloat) -> CGFloat {
        guard let screen = NSScreen.main else { return coordinate }

        let screenFrame = screen.visibleFrame
        let minX = screenFrame.minX + 8
        let maxX = screenFrame.maxX - Constants.windowWidth - 8

        return max(minX, min(coordinate, maxX))
    }

    // MARK: - Key Window Behavior

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    // MARK: - Close

    override func close() {
        // アニメーション付きで閉じる
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            self.animator().alphaValue = 0
        } completionHandler: {
            super.close()
        }
    }
}
