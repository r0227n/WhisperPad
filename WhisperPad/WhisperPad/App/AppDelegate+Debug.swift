//
//  AppDelegate+Debug.swift
//  WhisperPad
//

#if DEBUG
import AppKit
import AVFoundation
import ComposableArchitecture
import Dependencies
import os.log
import UniformTypeIdentifiers
import UserNotifications

// MARK: - Debug Menu and Actions

extension AppDelegate {
    /// デバッグメニューを追加
    func addDebugMenu(to menu: NSMenu) {
        let debugMenu = NSMenu(title: "Debug")

        let debugIdle = NSMenuItem(
            title: "Set Idle",
            action: #selector(debugSetIdle),
            keyEquivalent: ""
        )
        debugIdle.target = self
        debugMenu.addItem(debugIdle)

        let debugRecording = NSMenuItem(
            title: "Set Recording",
            action: #selector(debugSetRecording),
            keyEquivalent: ""
        )
        debugRecording.target = self
        debugMenu.addItem(debugRecording)

        let debugTranscribing = NSMenuItem(
            title: "Set Transcribing",
            action: #selector(debugSetTranscribing),
            keyEquivalent: ""
        )
        debugTranscribing.target = self
        debugMenu.addItem(debugTranscribing)

        let debugCompleted = NSMenuItem(
            title: "Set Completed",
            action: #selector(debugSetCompleted),
            keyEquivalent: ""
        )
        debugCompleted.target = self
        debugMenu.addItem(debugCompleted)

        let debugError = NSMenuItem(
            title: "Set Error",
            action: #selector(debugSetError),
            keyEquivalent: ""
        )
        debugError.target = self
        debugMenu.addItem(debugError)

        // Permissions サブメニュー
        debugMenu.addItem(NSMenuItem.separator())
        addPermissionsSubmenu(to: debugMenu)

        // Output サブメニュー
        addOutputSubmenu(to: debugMenu)

        // WhisperKit サブメニュー
        debugMenu.addItem(NSMenuItem.separator())
        addWhisperKitSubmenu(to: debugMenu)

        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        menu.addItem(debugItem)
    }

    /// Permissions サブメニューを追加
    private func addPermissionsSubmenu(to debugMenu: NSMenu) {
        let permissionsMenu = NSMenu(title: "Permissions")

        // マイク権限状態（動的タイトル）
        let micStatusItem = NSMenuItem(
            title: "Microphone: Checking...",
            action: nil,
            keyEquivalent: ""
        )
        micStatusItem.tag = DebugMenuItemTag.micPermissionStatus.rawValue
        permissionsMenu.addItem(micStatusItem)

        // マイク権限リクエスト
        let requestMicItem = NSMenuItem(
            title: "Request Microphone Permission",
            action: #selector(debugRequestMicrophonePermission),
            keyEquivalent: ""
        )
        requestMicItem.target = self
        permissionsMenu.addItem(requestMicItem)

        // マイク設定を開く
        let openMicSettingsItem = NSMenuItem(
            title: "Open Microphone Settings...",
            action: #selector(debugOpenMicrophoneSettings),
            keyEquivalent: ""
        )
        openMicSettingsItem.target = self
        permissionsMenu.addItem(openMicSettingsItem)

        let permissionsItem = NSMenuItem(title: "Permissions", action: nil, keyEquivalent: "")
        permissionsItem.submenu = permissionsMenu
        debugMenu.addItem(permissionsItem)
    }

    @objc func debugSetIdle() {
        debugLogger.debug("Debug: Set Idle")
        store.send(.resetToIdle)
    }

    @objc func debugSetRecording() {
        debugLogger.debug("Debug: Set Recording")
        store.send(.startRecording)
    }

    @objc func debugSetTranscribing() {
        debugLogger.debug("Debug: Set Transcribing")
        store.send(.stopRecording)
    }

    @objc func debugSetCompleted() {
        debugLogger.debug("Debug: Set Completed")
        store.send(.transcriptionCompleted("Debug transcription text"))
    }

    @objc func debugSetError() {
        debugLogger.debug("Debug: Set Error")
        store.send(.errorOccurred("Debug error message"))
    }

    // MARK: - Permission Debug Actions

    @objc func debugRequestMicrophonePermission() {
        debugLogger.debug("Debug: Requesting microphone permission")
        // アプリをアクティブ化してダイアログを前面に表示
        NSApp.activate(ignoringOtherApps: true)
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            self?.debugLogger.debug("Debug: Microphone permission result: \(granted)")
            DispatchQueue.main.async {
                self?.updatePermissionMenuItems()
            }
        }
    }

    @objc func debugOpenMicrophoneSettings() {
        debugLogger.debug("Debug: Opening microphone settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 権限メニュー項目を更新
    func updatePermissionMenuItems() {
        guard let menu = statusMenu else { return }

        // Debug メニューを探す
        for item in menu.items {
            guard let submenu = item.submenu, submenu.title == "Debug" else { continue }
            // Permissions サブメニューを探す
            for debugItem in submenu.items {
                guard let permMenu = debugItem.submenu, permMenu.title == "Permissions" else { continue }

                // マイク権限状態を更新
                if let micItem = permMenu.item(withTag: DebugMenuItemTag.micPermissionStatus.rawValue) {
                    let status = AVCaptureDevice.authorizationStatus(for: .audio)
                    micItem.title = "Microphone: \(statusEmoji(for: status)) \(statusText(for: status))"
                }
            }
        }
    }

    private func statusEmoji(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "✅"
        case .denied: return "❌"
        case .restricted: return "🚫"
        case .notDetermined: return "❓"
        @unknown default: return "❓"
        }
    }

    private func statusText(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Output Debug Menu

    /// Output サブメニューを追加
    private func addOutputSubmenu(to debugMenu: NSMenu) {
        let outputMenu = NSMenu(title: "Output")

        // Test Copy to Clipboard
        let copyItem = NSMenuItem(
            title: "Test Copy to Clipboard",
            action: #selector(debugTestCopyToClipboard),
            keyEquivalent: ""
        )
        copyItem.target = self
        outputMenu.addItem(copyItem)

        // Test Show Notification
        let notificationItem = NSMenuItem(
            title: "Test Show Notification",
            action: #selector(debugTestShowNotification),
            keyEquivalent: ""
        )
        notificationItem.target = self
        outputMenu.addItem(notificationItem)

        // Test Play Sound
        let soundItem = NSMenuItem(
            title: "Test Play Sound",
            action: #selector(debugTestPlaySound),
            keyEquivalent: ""
        )
        soundItem.target = self
        outputMenu.addItem(soundItem)

        outputMenu.addItem(NSMenuItem.separator())

        // Save Transcription to File
        let saveToFileItem = NSMenuItem(
            title: "Save Transcription to File...",
            action: #selector(debugSaveTranscriptionToFile),
            keyEquivalent: ""
        )
        saveToFileItem.target = self
        outputMenu.addItem(saveToFileItem)

        outputMenu.addItem(NSMenuItem.separator())

        // Notification permission status
        let notifStatusItem = NSMenuItem(
            title: "Notification: Checking...",
            action: nil,
            keyEquivalent: ""
        )
        notifStatusItem.tag = MenuItemTag.notificationPermissionStatus.rawValue
        outputMenu.addItem(notifStatusItem)

        // Request Notification Permission
        let requestNotifItem = NSMenuItem(
            title: "Request Notification Permission",
            action: #selector(debugRequestNotificationPermission),
            keyEquivalent: ""
        )
        requestNotifItem.target = self
        outputMenu.addItem(requestNotifItem)

        // Open Notification Settings
        let openNotifSettingsItem = NSMenuItem(
            title: "Open Notification Settings...",
            action: #selector(debugOpenNotificationSettings),
            keyEquivalent: ""
        )
        openNotifSettingsItem.target = self
        outputMenu.addItem(openNotifSettingsItem)

        let outputItem = NSMenuItem(title: "Output", action: nil, keyEquivalent: "")
        outputItem.submenu = outputMenu
        debugMenu.addItem(outputItem)
    }

    // MARK: - Output Debug Actions

    @objc func debugTestCopyToClipboard() {
        debugLogger.debug("Debug: Testing clipboard copy")
        let testText = "WhisperPad Debug: Clipboard Test - \(Date())"

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(testText, forType: .string)

        debugLogger.debug("Debug: Clipboard copy result: \(success)")

        showAlert(
            title: success ? "Clipboard Copy Succeeded" : "Clipboard Copy Failed",
            message: success ? "Text copied: \(testText)" : "Failed to copy text to clipboard"
        )
    }

    @objc func debugTestShowNotification() {
        debugLogger.debug("Debug: Testing notification")

        let content = UNMutableNotificationContent()
        content.title = "WhisperPad Debug"
        content.body = "Test notification - \(Date())"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.debugLogger.error("Debug: Notification failed: \(error.localizedDescription)")
                    self?.showAlert(title: "Notification Failed", message: error.localizedDescription)
                } else {
                    self?.debugLogger.debug("Debug: Notification sent successfully")
                }
            }
        }
    }

    @objc func debugTestPlaySound() {
        debugLogger.debug("Debug: Testing completion sound")
        if let sound = NSSound(named: "Glass") {
            sound.play()
            debugLogger.debug("Debug: Sound played")
        } else {
            debugLogger.warning("Debug: Sound 'Glass' not found")
            showAlert(title: "Sound Not Found", message: "System sound 'Glass' was not found")
        }
    }

    @objc func debugSaveTranscriptionToFile() {
        debugLogger.debug("Debug: Save transcription to file")

        // 文字起こし結果を取得
        guard let transcription = store.state.lastTranscription, !transcription.isEmpty else {
            showAlert(
                title: "No Transcription",
                message: "No transcription text available. Please run a transcription first."
            )
            return
        }

        // NSSavePanel を表示
        let savePanel = NSSavePanel()
        savePanel.title = "Save Transcription"
        savePanel.nameFieldStringValue = generateDefaultFileName()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.canCreateDirectories = true

        NSApp.activate(ignoringOtherApps: true)

        savePanel.begin { [weak self] response in
            guard response == .OK, let url = savePanel.url else {
                self?.debugLogger.debug("Debug: Save cancelled")
                return
            }

            do {
                try transcription.write(to: url, atomically: true, encoding: .utf8)
                self?.debugLogger.info("Debug: Transcription saved to \(url.path)")
                self?.showAlert(
                    title: "File Saved",
                    message: "Transcription saved to:\n\(url.path)"
                )
            } catch {
                self?.debugLogger.error("Debug: Failed to save: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Save Failed",
                    message: "Failed to save file: \(error.localizedDescription)"
                )
            }
        }
    }

    private func generateDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "WhisperPad_\(formatter.string(from: Date())).txt"
    }

    @objc func debugRequestNotificationPermission() {
        debugLogger.debug("Debug: Requesting notification permission")
        NSApp.activate(ignoringOtherApps: true)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            self?.debugLogger.debug("Debug: Notification permission result: \(granted), error: \(String(describing: error))")
            DispatchQueue.main.async {
                self?.updateOutputMenuItems()
            }
        }
    }

    @objc func debugOpenNotificationSettings() {
        debugLogger.debug("Debug: Opening notification settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Output メニュー項目を更新
    func updateOutputMenuItems() {
        guard let menu = statusMenu else { return }

        // Debug メニューを探す
        for item in menu.items {
            guard let submenu = item.submenu, submenu.title == "Debug" else { continue }
            // Output サブメニューを探す
            for debugItem in submenu.items {
                guard let outputMenu = debugItem.submenu, outputMenu.title == "Output" else { continue }

                // 通知権限状態を更新
                if let notifItem = outputMenu.item(withTag: MenuItemTag.notificationPermissionStatus.rawValue) {
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            let status = settings.authorizationStatus
                            let emoji: String
                            let text: String
                            switch status {
                            case .authorized:
                                emoji = "✅"
                                text = "Authorized"
                            case .denied:
                                emoji = "❌"
                                text = "Denied"
                            case .notDetermined:
                                emoji = "❓"
                                text = "Not Determined"
                            case .provisional:
                                emoji = "⚠️"
                                text = "Provisional"
                            case .ephemeral:
                                emoji = "⏳"
                                text = "Ephemeral"
                            @unknown default:
                                emoji = "❓"
                                text = "Unknown"
                            }
                            notifItem.title = "Notification: \(emoji) \(text)"
                        }
                    }
                }
            }
        }
    }

    // MARK: - WhisperKit Debug Menu

    /// WhisperKit サブメニューを追加
    private func addWhisperKitSubmenu(to debugMenu: NSMenu) {
        let whisperKitMenu = NSMenu(title: "WhisperKit")

        // モデル一覧を取得
        let fetchModelsItem = NSMenuItem(
            title: "Fetch Available Models",
            action: #selector(debugFetchAvailableModels),
            keyEquivalent: ""
        )
        fetchModelsItem.target = self
        whisperKitMenu.addItem(fetchModelsItem)

        // 推奨モデルを取得
        let recommendedModelItem = NSMenuItem(
            title: "Get Recommended Model",
            action: #selector(debugGetRecommendedModel),
            keyEquivalent: ""
        )
        recommendedModelItem.target = self
        whisperKitMenu.addItem(recommendedModelItem)

        whisperKitMenu.addItem(NSMenuItem.separator())

        // tiny モデルをダウンロード
        let downloadTinyItem = NSMenuItem(
            title: "Download tiny Model",
            action: #selector(debugDownloadTinyModel),
            keyEquivalent: ""
        )
        downloadTinyItem.target = self
        whisperKitMenu.addItem(downloadTinyItem)

        let whisperKitItem = NSMenuItem(title: "WhisperKit", action: nil, keyEquivalent: "")
        whisperKitItem.submenu = whisperKitMenu
        debugMenu.addItem(whisperKitItem)
    }

    // MARK: - WhisperKit Debug Actions

    @objc func debugFetchAvailableModels() {
        debugLogger.debug("Debug: Fetching available models")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            do {
                let models = try await transcriptionClient.fetchAvailableModels()
                debugLogger.info("Debug: Found \(models.count) models")
                for model in models {
                    debugLogger.info("  - \(model)")
                }
                await MainActor.run {
                    showAlert(
                        title: "Available Models",
                        message: "Found \(models.count) models:\n\n\(models.joined(separator: "\n"))"
                    )
                }
            } catch {
                debugLogger.error("Debug: Failed to fetch models: \(error.localizedDescription)")
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to fetch models: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func debugGetRecommendedModel() {
        debugLogger.debug("Debug: Getting recommended model")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            let recommended = await transcriptionClient.recommendedModel()
            debugLogger.info("Debug: Recommended model: \(recommended)")
            await MainActor.run {
                showAlert(title: "Recommended Model", message: recommended)
            }
        }
    }

    @objc func debugDownloadTinyModel() {
        debugLogger.debug("Debug: Downloading tiny model")

        @Dependency(\.transcriptionClient) var transcriptionClient

        Task {
            do {
                await MainActor.run {
                    showAlert(
                        title: "Downloading",
                        message: "Downloading openai_whisper-tiny model...\nThis may take a while."
                    )
                }
                let url = try await transcriptionClient.downloadModel("openai_whisper-tiny") { progress in
                    self.debugLogger.debug("Debug: Download progress: \(Int(progress * 100))%")
                }
                debugLogger.info("Debug: Model downloaded to: \(url.path)")
                await MainActor.run {
                    showAlert(
                        title: "Download Complete",
                        message: "Model downloaded to:\n\(url.path)"
                    )
                }
            } catch {
                debugLogger.error("Debug: Failed to download model: \(error.localizedDescription)")
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to download model: \(error.localizedDescription)")
                }
            }
        }
    }

    /// アラートを表示
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

// MARK: - Debug Menu Item Tags

/// デバッグメニュー項目を識別するためのタグ
enum DebugMenuItemTag: Int {
    case micPermissionStatus = 400
}

// MARK: - Debug Logger

extension AppDelegate {
    var debugLogger: Logger {
        Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.example.WhisperPad",
            category: "AppDelegate.Debug"
        )
    }
}
#endif
