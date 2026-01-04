//
//  AppDelegate+Model.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Dependencies
import os.log

// MARK: - Model Management

extension AppDelegate {
    /// モデル変更通知の監視を設定
    func setupModelChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModelChanged),
            name: .modelChanged,
            object: nil
        )
    }

    /// モデル変更通知を受信した際の処理
    @objc func handleModelChanged(_ notification: Notification) {
        logger.debug("Model change notification received")
        // キャッシュを無効化し、次回メニュー表示時に再取得
        setCachedDownloadedModels([])
        // メニュー項目のタイトルを更新
        updateModelMenuForCurrentState()
    }

    /// 起動時にダウンロード済みモデルを取得してキャッシュを初期化
    ///
    /// メニューバーのモデル表示を正しく行うために、アプリ起動時に
    /// ダウンロード済みモデルを取得してキャッシュに保存する。
    func initializeModelCache() {
        Task { @MainActor in
            do {
                // カスタムストレージ場所を設定（ブックマーク解決）
                let settings = store.settings.settings
                if let bookmarkData = settings.transcription.storageBookmarkData {
                    @Dependency(\.userDefaultsClient) var userDefaultsClient
                    if let url = await userDefaultsClient.resolveBookmark(bookmarkData) {
                        await modelClient.setStorageLocation(url)
                    }
                }

                let models = try await modelClient.fetchDownloadedModelsAsWhisperModels()
                setCachedDownloadedModels(models)

                // defaultModel の整合性チェック
                let modelIds = models.map(\.id)
                let validationResult = modelClient.validateDefaultModel(modelIds)
                switch validationResult {
                case let .success(validModel):
                    let currentDefault = loadDefaultModelSync()
                    if currentDefault != validModel {
                        store.send(.selectModel(validModel))
                    }
                case .failure:
                    // モデルがない場合は何もしない（メニューで適切に表示される）
                    break
                }

                // メニュー表示を更新
                updateModelMenuForCurrentState()
            } catch {
                logger.error("Failed to initialize model cache: \(error.localizedDescription)")
            }
        }
    }

    /// UserDefaults からデフォルトモデルを同期的に読み込む
    ///
    /// メニュー表示時にデフォルトモデル名を取得するために使用する。
    /// - Returns: 保存されているモデル名、未設定の場合は nil
    func loadDefaultModelSync() -> String? {
        modelClient.loadDefaultModelSync()
    }

    /// モデルメニュー項目がタップされた
    @objc func modelMenuItemTapped(_ sender: NSMenuItem) {
        guard let modelName = sender.representedObject as? String else {
            logger.warning("Model menu item tapped but no model name found")
            return
        }
        logger.info("Model selected: \(modelName)")
        store.send(.selectModel(modelName))
    }
}
