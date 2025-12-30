//
//  AppDelegate+Debug.swift
//  WhisperPad
//

#if DEBUG
import AppKit
import AVFoundation
import Dependencies
import os.log

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
