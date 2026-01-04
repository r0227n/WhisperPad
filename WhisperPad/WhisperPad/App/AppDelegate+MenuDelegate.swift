//
//  AppDelegate+MenuDelegate.swift
//  WhisperPad
//

import AppKit
import Dependencies

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // メインメニューが開かれた場合、モデルメニューの状態を更新
        if menu == statusMenu {
            updateModelMenuForCurrentState()
        }

        // モデルサブメニューが開かれた場合、ダウンロード済みモデルを更新
        if menu == modelSubmenu {
            refreshModelSubmenu()
        }

        #if DEBUG
        updatePermissionMenuItems()
        updateOutputMenuItems()
        #endif
    }

    /// モデルサブメニューを更新
    ///
    /// サブメニューが開かれるたびにダウンロード済みモデルを取得し、メニュー項目を更新する。
    /// defaultModel がダウンロード済みモデルに存在しない場合、最初のモデルを自動選択する。
    func refreshModelSubmenu() {
        // キャッシュがあれば即座に表示
        if !getCachedDownloadedModels().isEmpty {
            updateModelSubmenuItems(getCachedDownloadedModels())
        }

        // バックグラウンドで最新を取得
        Task { @MainActor in
            do {
                let models = try await modelClient.fetchDownloadedModelsAsWhisperModels()
                if models != getCachedDownloadedModels() {
                    setCachedDownloadedModels(models)
                    updateModelSubmenuItems(models)
                }

                // defaultModel の整合性チェック（validateDefaultModel を使用）
                let modelIds = models.map(\.id)
                let validationResult = modelClient.validateDefaultModel(modelIds)
                switch validationResult {
                case let .success(validModel):
                    // 有効なモデルが確認された、または自動選択された場合
                    let currentDefault = loadDefaultModelSync()
                    if currentDefault != validModel {
                        // 自動選択されたモデルを適用
                        store.send(.selectModel(validModel))
                        updateModelSubmenuItems(models)
                    }
                case let .failure(error):
                    // モデルが0件の場合はエラーダイアログを表示
                    showModelErrorAlert(error)
                }
            } catch {
                // モデル取得失敗時はエラーダイアログを表示
                showModelErrorAlert(.fetchDownloadedModelsFailed(error.localizedDescription))
            }
        }
    }

    /// モデル関連エラーのアラートを表示
    ///
    /// - Parameter error: 表示するエラー
    func showModelErrorAlert(_ error: ModelClientError) {
        let languageCode = resolveLanguageCode()
        let iconSettings = store.settings.settings.general.menuBarIconSettings
        showLocalizedAlert(
            style: .critical,
            titleKey: "error.dialog.model.title",
            message: error.localizedDescription ?? "",
            languageCode: languageCode,
            iconSettings: iconSettings
        )
    }

    /// 現在のロケール設定から言語コードを解決
    ///
    /// - Returns: 言語コード（"en" または "ja"）
    func resolveLanguageCode() -> String {
        if let identifier = store.settings.settings.general.preferredLocale.identifier {
            return identifier
        }
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        return Locale(identifier: systemLanguage).language.languageCode?.identifier ?? "en"
    }

    /// モデルサブメニューの項目を更新
    ///
    /// - Parameter models: ダウンロード済みモデルの配列
    func updateModelSubmenuItems(_ models: [WhisperModel]) {
        guard let submenu = modelSubmenu else { return }

        submenu.removeAllItems()

        // モデルがない場合
        guard !models.isEmpty else {
            let noModelsItem = NSMenuItem(
                title: localizedAppString(forKey: "menu.model.no_models"),
                action: nil,
                keyEquivalent: ""
            )
            noModelsItem.isEnabled = false
            submenu.addItem(noModelsItem)
            return
        }

        let currentDefault = loadDefaultModelSync()

        // defaultModel がダウンロード済みモデルに存在するか確認
        // 存在しない場合はチェックマークを表示しない（refreshModelSubmenu で修正される）
        let validDefault: String? = if let defaultModel = currentDefault,
                                       models.contains(where: { $0.id == defaultModel }) {
            defaultModel
        } else {
            nil
        }

        for model in models {
            let modelMenuItem = NSMenuItem(
                title: model.displayName,
                action: #selector(modelMenuItemTapped(_:)),
                keyEquivalent: ""
            )
            modelMenuItem.target = self
            // representedObject にはモデルIDを保持（内部ロジックで使用）
            modelMenuItem.representedObject = model.id

            // 有効な defaultModel にのみチェックマーク
            if model.id == validDefault {
                modelMenuItem.state = .on
            }

            submenu.addItem(modelMenuItem)
        }
    }
}
