//
//  AppDelegate+RecordingTimeDisplay.swift
//  WhisperPad
//

import AppKit

// MARK: - Recording Time Display

extension AppDelegate {
    /// 録音時間を「MM:SS」形式でフォーマット
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// ステータスバーに録音時間を表示
    func setRecordingTimeDisplay(_ duration: TimeInterval) {
        guard let button = statusItem?.button else { return }
        // 等幅数字フォントで表示（数字幅が変わっても揃う）
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        ]
        button.attributedTitle = NSAttributedString(
            string: formatDuration(duration),
            attributes: attributes
        )
    }

    /// ステータスバーから録音時間表示をクリア
    func clearRecordingTimeDisplay() {
        statusItem?.button?.title = ""
    }
}
