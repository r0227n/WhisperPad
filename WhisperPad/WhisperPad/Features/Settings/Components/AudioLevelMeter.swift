//
//  AudioLevelMeter.swift
//  WhisperPad
//

import SwiftUI

/// オーディオレベルメーター
///
/// リアルタイムの音声レベルを視覚的に表示するコンポーネント。
/// 色のグラデーションでレベルの状態（安全/良好/大音量/ピーク）を示します。
struct AudioLevelMeter: View {
    /// 音声レベル（dB値: -60 to 0）
    let level: Float
    /// 数値表示の有無
    let showNumericValue: Bool
    /// メーターの高さ
    let height: CGFloat
    /// インタラクティブモード（しきい値設定用）
    let isInteractive: Bool

    init(
        level: Float,
        showNumericValue: Bool = true,
        height: CGFloat = 8,
        isInteractive: Bool = false
    ) {
        self.level = level
        self.showNumericValue = showNumericValue
        self.height = height
        self.isInteractive = isInteractive
    }

    var body: some View {
        HStack(spacing: 8) {
            // メーターバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))

                    // レベルバー
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(levelGradient)
                        .frame(width: barWidth(in: geometry.size.width))
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
            .frame(height: height)

            // 数値表示
            if showNumericValue {
                Text("\(Int(level)) dB")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility.audio_level", comment: "Audio level"))
        .accessibilityValue("\(Int(level)) decibels")
    }

    // MARK: - Private Methods

    /// バーの幅を計算
    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        // -60dB to 0dB を 0% to 100% にマッピング
        let normalizedLevel = (level + 60) / 60
        let clampedLevel = max(0, min(1, normalizedLevel))
        return totalWidth * CGFloat(clampedLevel)
    }

    /// レベルに応じたグラデーション
    private var levelGradient: LinearGradient {
        let colors: [Color]
        let startPoint: UnitPoint = .leading
        let endPoint: UnitPoint = .trailing

        // レベルに応じて色を変更
        if level >= -3 {
            // ピーク: 赤
            colors = [.red, .red]
        } else if level >= -6 {
            // 大音量: オレンジ
            colors = [.orange, .red]
        } else if level >= -18 {
            // 良好: 黄色〜オレンジ
            colors = [.yellow, .orange]
        } else {
            // 安全: 緑〜黄色
            colors = [.green, .yellow]
        }

        return LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Preview

#Preview("Normal") {
    VStack(spacing: 20) {
        Text("Audio Level Meter Examples")
            .font(.headline)

        // 様々なレベルの例
        VStack(alignment: .leading, spacing: 12) {
            AudioLevelMeter(level: -60)
            Text("Silent (-60 dB)")
                .font(.caption)
                .foregroundColor(.secondary)

            AudioLevelMeter(level: -40)
            Text("Quiet (-40 dB)")
                .font(.caption)
                .foregroundColor(.secondary)

            AudioLevelMeter(level: -20)
            Text("Normal (-20 dB)")
                .font(.caption)
                .foregroundColor(.secondary)

            AudioLevelMeter(level: -12)
            Text("Good (-12 dB)")
                .font(.caption)
                .foregroundColor(.secondary)

            AudioLevelMeter(level: -6)
            Text("Loud (-6 dB)")
                .font(.caption)
                .foregroundColor(.secondary)

            AudioLevelMeter(level: -3)
            Text("Peak (-3 dB)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Without Numeric Value") {
    VStack(spacing: 12) {
        AudioLevelMeter(level: -20, showNumericValue: false)
        AudioLevelMeter(level: -10, showNumericValue: false)
        AudioLevelMeter(level: -5, showNumericValue: false)
    }
    .padding()
    .frame(width: 300)
}

#Preview("Different Heights") {
    VStack(spacing: 12) {
        AudioLevelMeter(level: -20, height: 4)
        AudioLevelMeter(level: -20, height: 8)
        AudioLevelMeter(level: -20, height: 12)
        AudioLevelMeter(level: -20, height: 16)
    }
    .padding()
    .frame(width: 400)
}
