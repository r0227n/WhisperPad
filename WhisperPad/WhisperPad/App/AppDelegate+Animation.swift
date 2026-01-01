//
//  AppDelegate+Animation.swift
//  WhisperPad
//

import AppKit

// MARK: - Animation

extension AppDelegate {
    /// アイコンアニメーションを開始
    /// - Parameter iconConfig: アニメーションに使用するアイコン設定
    func startGearAnimation(with iconConfig: StatusIconConfig) {
        guard getAnimationTimer() == nil else { return }

        setAnimationFrame(0)
        setAnimationIconConfig(iconConfig)
        setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateGearAnimationFrame()
        }
        setAnimationTimer(timer)
    }

    /// ギアアニメーションを停止
    func stopGearAnimation() {
        getAnimationTimer()?.invalidate()
        setAnimationTimer(nil)
        setAnimationIconConfig(nil)
    }

    /// アイコンアニメーションのフレームを更新
    func updateGearAnimationFrame() {
        guard let button = getStatusItem()?.button,
              let iconConfig = getAnimationIconConfig() else { return }

        let newFrame = (getAnimationFrame() + 1) % 8
        setAnimationFrame(newFrame)

        // ベースカラーのHSB値を取得して色相を変化させる
        let baseColor = iconConfig.color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if let convertedColor = baseColor.usingColorSpace(.deviceRGB) {
            convertedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        } else {
            // フォールバック: デフォルトの青系
            hue = 0.6
            saturation = 0.8
            brightness = 0.9
            alpha = 1.0
        }

        // 色相を少し変化させてアニメーション効果を出す
        let animatedHue = hue + (CGFloat(newFrame) / 8.0) * 0.1
        let color = NSColor(
            hue: animatedHue.truncatingRemainder(dividingBy: 1.0),
            saturation: saturation,
            brightness: brightness,
            alpha: alpha
        )

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))

        let image = NSImage(systemSymbolName: iconConfig.symbolName, accessibilityDescription: "Processing")
        button.image = image?.withSymbolConfiguration(config)
    }

    // MARK: - Pulse Animation

    /// パルスアニメーションを開始
    /// - Parameter iconConfig: アニメーションに使用するアイコン設定
    func startPulseAnimation(with iconConfig: StatusIconConfig) {
        guard getPulseTimer() == nil else { return }

        // Reduce Motion チェック
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)
            return
        }

        setPulsePhase(0)
        setStatusIcon(symbolName: iconConfig.symbolName, color: iconConfig.color)

        // 0.8s cycle / 20 frames = 0.04s interval
        let timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            self?.updatePulseAnimationFrame()
        }
        setPulseTimer(timer)
    }

    /// パルスアニメーションのフレームを更新
    func updatePulseAnimationFrame() {
        guard let button = getStatusItem()?.button else { return }

        // Sine wave: 0.5 to 1.0
        let newPhase = getPulsePhase() + 0.04 / 0.8 * 2 * .pi // Complete cycle in 0.8s
        setPulsePhase(newPhase)
        let opacity = 0.75 + 0.25 * sin(newPhase) // Range: 0.5 to 1.0
        button.alphaValue = CGFloat(opacity)
    }

    /// パルスアニメーションを停止
    func stopPulseAnimation() {
        getPulseTimer()?.invalidate()
        setPulseTimer(nil)
        getStatusItem()?.button?.alphaValue = 1.0
    }

    /// すべてのアニメーションを停止
    func stopAllAnimations() {
        stopGearAnimation()
        stopPulseAnimation()
    }
}
