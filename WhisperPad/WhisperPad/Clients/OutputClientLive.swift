//
//  OutputClientLive.swift
//  WhisperPad
//

import AppKit
import Dependencies
import OSLog
import UserNotifications

private let logger = Logger(subsystem: "com.whisperpad", category: "OutputClientLive")

// MARK: - DependencyKey

extension OutputClient: DependencyKey {
    static var liveValue: Self {
        Self(
            copyToClipboard: { text in
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                let success = pasteboard.setString(text, forType: .string)

                if success {
                    logger.info("Text copied to clipboard (\(text.count) characters)")
                } else {
                    logger.error("Failed to copy text to clipboard")
                }

                return success
            },
            saveToFile: { text, settings in
                let fileManager = FileManager.default

                // 出力ディレクトリを作成（存在しない場合）
                if !fileManager.fileExists(atPath: settings.outputDirectory.path) {
                    do {
                        try fileManager.createDirectory(
                            at: settings.outputDirectory,
                            withIntermediateDirectories: true
                        )
                        logger.info("Created output directory: \(settings.outputDirectory.path)")
                    } catch {
                        logger.error("Failed to create directory: \(error.localizedDescription)")
                        throw OutputError.directoryCreationFailed(error.localizedDescription)
                    }
                }

                // 連番の場合、既存ファイルをチェックして次の番号を決定
                let sequentialNumber: Int = if settings.fileNameFormat == .sequential {
                    Self.findNextSequentialNumber(in: settings.outputDirectory)
                } else {
                    1
                }

                // ファイルパスを生成
                let filePath = settings.generateFilePath(sequentialNumber: sequentialNumber)

                // コンテンツを準備
                var content = text
                if settings.includeMetadata {
                    let metadata = Self.generateMetadata()
                    content = """
                    ---
                    \(metadata)
                    ---

                    \(text)
                    """
                }

                // ファイルに書き込み
                do {
                    try content.write(to: filePath, atomically: true, encoding: .utf8)
                    logger.info("Text saved to file: \(filePath.path)")
                    return filePath
                } catch {
                    logger.error("Failed to write file: \(error.localizedDescription)")
                    throw OutputError.fileWriteFailed(error.localizedDescription)
                }
            },
            showNotification: { title, body in
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = nil // サウンドは別途再生

                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil // 即時配信
                )

                do {
                    try await UNUserNotificationCenter.current().add(request)
                    logger.info("Notification shown: \(title)")
                } catch {
                    logger.error("Failed to show notification: \(error.localizedDescription)")
                }
            },
            playCompletionSound: {
                await MainActor.run {
                    if let sound = NSSound(named: "Glass") {
                        sound.play()
                        logger.debug("Completion sound played")
                    } else {
                        logger.warning("Completion sound 'Glass' not found")
                    }
                }
            },
            requestNotificationPermission: {
                do {
                    let granted = try await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound])
                    logger.info("Notification permission: \(granted ? "granted" : "denied")")
                    return granted
                } catch {
                    logger.error("Notification permission request failed: \(error.localizedDescription)")
                    return false
                }
            }
        )
    }

    // MARK: - Private Helpers

    /// 次の連番を検索
    private static func findNextSequentialNumber(in directory: URL) -> Int {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return 1
        }

        // WhisperPad_XXX.* 形式のファイルから最大番号を見つける
        let pattern = #"WhisperPad_(\d{3})\."#
        let regex = try? NSRegularExpression(pattern: pattern)

        var maxNumber = 0
        for file in files {
            let range = NSRange(file.startIndex..., in: file)
            if let match = regex?.firstMatch(in: file, range: range),
               let numberRange = Range(match.range(at: 1), in: file) {
                if let number = Int(file[numberRange]) {
                    maxNumber = max(maxNumber, number)
                }
            }
        }

        return maxNumber + 1
    }

    /// メタデータを生成
    private static func generateMetadata() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: Date())

        return """
        created: \(dateString)
        app: WhisperPad
        """
    }
}
