//
//  AppDelegate+StatusIcon.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture

// MARK: - State-based UI Updates

extension AppDelegate {
    /// 現在の状態に応じてアイコンを更新
    func updateIconForCurrentState() {
        // カスタムアイコン設定を取得
        let iconSettings = store.settings.settings.general.menuBarIconSettings

        // モデル状態を優先してチェック（モデル読み込み中は他の状態より優先）
        switch store.modelState {
        case .unloaded:
            // 未初期化状態を明示
            stopAllAnimations()
            let config = iconSettings.unloaded
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()
            return

        case .loading, .downloading:
            stopAllAnimations()
            let config = iconSettings.loading
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()
            return

        case .loaded, .error:
            break // appStatusに基づくアイコン更新を継続
        }

        switch store.appStatus {
        case .idle:
            stopAllAnimations()
            let config = iconSettings.idle
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()

        case .recording:
            stopGearAnimation()
            let config = iconSettings.recording
            startPulseAnimation(with: config)
            setRecordingTimeDisplay(store.recording.currentDuration)

        case .paused:
            stopAllAnimations()
            let config = iconSettings.paused
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            setRecordingTimeDisplay(store.recording.currentDuration)

        case .transcribing:
            stopPulseAnimation()
            let config = iconSettings.transcribing
            startGearAnimation(with: config)
            clearRecordingTimeDisplay()

        case .completed:
            stopAllAnimations()
            let config = iconSettings.completed
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()

        case .error:
            stopAllAnimations()
            let config = iconSettings.error
            setStatusIcon(symbolName: config.symbolName, color: config.color)
            clearRecordingTimeDisplay()
        }
    }

    /// ステータスアイコンを設定
    /// - Parameters:
    ///   - symbolName: SF Symbol 名
    ///   - color: アイコンの色
    func setStatusIcon(symbolName: String, color: NSColor) {
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "WhisperPad")
        button.image = image?.withSymbolConfiguration(config)
    }
}
