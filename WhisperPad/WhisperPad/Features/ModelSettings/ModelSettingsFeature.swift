//
//  ModelSettingsFeature.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - ModelSettings Feature

/// モデル設定機能の TCA Reducer
///
/// WhisperKitモデルの選択、ダウンロード、ストレージ管理を行います。
@Reducer
struct ModelSettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable, Sendable {
        /// 文字起こし設定
        var transcription: TranscriptionSettings

        /// 利用可能なモデル一覧
        var availableModels: [WhisperModel] = []

        /// ダウンロード済みモデル一覧（ローカルディレクトリスキャンで取得）
        var downloadedModels: [WhisperModel] = []

        /// モデル一覧を読み込み中かどうか
        var isLoadingModels: Bool = false

        /// モデルのダウンロード進捗（モデル名: 進捗 0.0-1.0）
        var downloadProgress: [String: Double] = [:]

        /// 現在ダウンロード中のモデル名
        var downloadingModelName: String?

        /// ストレージ使用量（バイト）
        var storageUsage: Int64 = 0

        /// 現在のモデル保存先 URL
        var modelStorageURL: URL?

        /// 削除確認対象のモデル名
        var modelToDelete: String?

        /// 利用可能な文字起こし言語一覧
        var availableLanguages: [TranscriptionLanguage] = []

        /// ユーザーの優先ロケール（表示用）
        var preferredLocale: AppLocale

        init(
            transcription: TranscriptionSettings = .default,
            availableModels: [WhisperModel] = [],
            downloadedModels: [WhisperModel] = [],
            isLoadingModels: Bool = false,
            downloadProgress: [String: Double] = [:],
            downloadingModelName: String? = nil,
            storageUsage: Int64 = 0,
            modelStorageURL: URL? = nil,
            modelToDelete: String? = nil,
            availableLanguages: [TranscriptionLanguage] = [],
            preferredLocale: AppLocale = .system
        ) {
            self.transcription = transcription
            self.availableModels = availableModels
            self.downloadedModels = downloadedModels
            self.isLoadingModels = isLoadingModels
            self.downloadProgress = downloadProgress
            self.downloadingModelName = downloadingModelName
            self.storageUsage = storageUsage
            self.modelStorageURL = modelStorageURL
            self.modelToDelete = modelToDelete
            self.availableLanguages = availableLanguages
            self.preferredLocale = preferredLocale
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // MARK: - Lifecycle

        /// 画面表示時
        case onAppear

        // MARK: - Model Management

        /// モデル一覧を取得
        case fetchModels
        /// モデル一覧取得完了
        case modelsResponse(Result<[WhisperModel], Error>)
        /// ダウンロード済みモデル一覧を取得（ローカルスキャン）
        case fetchDownloadedModels
        /// ダウンロード済みモデル一覧取得完了
        case downloadedModelsResponse([WhisperModel])
        /// モデルを選択
        case selectModel(String)
        /// モデルをダウンロード
        case downloadModel(String)
        /// ダウンロード進捗更新
        case downloadProgress(String, Double)
        /// ダウンロード完了
        case downloadCompleted(String, Result<URL, Error>)
        /// モデル削除ボタンがタップされた（確認ダイアログを表示）
        case deleteModelButtonTapped(String)
        /// モデル削除を確認
        case confirmDeleteModel
        /// モデル削除をキャンセル
        case cancelDeleteModel
        /// モデルを削除
        case deleteModel(String)
        /// モデル削除完了
        case deleteModelResponse(String, Result<Void, Error>)

        // MARK: - Settings Updates

        /// 文字起こし設定を更新
        case updateTranscriptionSettings(TranscriptionSettings)

        // MARK: - Languages

        /// 利用可能な言語を更新
        case updateAvailableLanguages([TranscriptionLanguage])

        // MARK: - Storage Management

        /// ストレージ使用量を計算
        case calculateStorageUsage
        /// ストレージ使用量取得完了
        case storageUsageResponse(Int64)
        /// モデル保存先URLを取得
        case fetchModelStorageURL
        /// モデル保存先URL取得完了
        case modelStorageURLResponse(URL)
        /// ストレージ場所を選択
        case selectStorageLocation
        /// ストレージ場所選択完了
        case storageLocationSelected(Result<URL, Error>)

        // MARK: - Delegate

        /// 親 Reducer へのデリゲートアクション
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            /// モデルが選択された
            case modelSelected(String)
            /// 文字起こし設定が変更された
            case transcriptionSettingsChanged(TranscriptionSettings)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.modelClient) var modelClient

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Lifecycle

            case .onAppear:
                // 言語一覧を初期化
                let allLanguages = TranscriptionLanguage.allSupported
                if state.transcription.modelName.hasSuffix(".en") {
                    state.availableLanguages = allLanguages.filter {
                        $0.code == "auto" || $0.code == "en"
                    }
                } else {
                    state.availableLanguages = allLanguages
                }

                // ストレージ場所が既に設定されている場合はモデル一覧を取得
                // 設定されていない場合は先にストレージ場所を取得
                if state.modelStorageURL != nil {
                    return .merge(
                        .send(.fetchModels),
                        .send(.fetchDownloadedModels),
                        .send(.calculateStorageUsage)
                    )
                } else {
                    return .send(.fetchModelStorageURL)
                }

            // MARK: - Model Management

            case .fetchModels:
                state.isLoadingModels = true
                return .run { [modelClient] send in
                    do {
                        let modelNames = try await modelClient.fetchAvailableModels()
                        let recommendedModel = await modelClient.recommendedModel()
                        var models: [WhisperModel] = []
                        for name in modelNames {
                            let isDownloaded = await modelClient.isModelDownloaded(name)
                            models.append(WhisperModel.from(
                                id: name,
                                isDownloaded: isDownloaded,
                                isRecommended: name == recommendedModel
                            ))
                        }
                        models.sort { $0.id < $1.id }
                        await send(.modelsResponse(.success(models)))
                    } catch {
                        await send(.modelsResponse(.failure(error)))
                    }
                }

            case let .modelsResponse(.success(models)):
                state.isLoadingModels = false
                state.availableModels = models
                return .none

            case .modelsResponse(.failure):
                state.isLoadingModels = false
                return .none

            case .fetchDownloadedModels:
                return .run { [modelClient] send in
                    do {
                        let models = try await modelClient.fetchDownloadedModelsAsWhisperModels()
                        await send(.downloadedModelsResponse(models))
                    } catch {
                        await send(.downloadedModelsResponse([]))
                    }
                }

            case let .downloadedModelsResponse(models):
                state.downloadedModels = models
                // 利用可能なモデル一覧もダウンロード状態を更新
                for index in state.availableModels.indices {
                    let modelId = state.availableModels[index].id
                    state.availableModels[index].isDownloaded =
                        models.contains { $0.id == modelId }
                }
                return .none

            case let .selectModel(modelName):
                state.transcription.modelName = modelName
                // モデルが English-only の場合は言語を制限
                let allLanguages = TranscriptionLanguage.allSupported
                if modelName.hasSuffix(".en") {
                    state.availableLanguages = allLanguages.filter {
                        $0.code == "auto" || $0.code == "en"
                    }
                    // 現在の言語が英語以外なら auto に変更
                    if state.transcription.language.code != "auto",
                       state.transcription.language.code != "en" {
                        state.transcription.language = .auto
                    }
                } else {
                    state.availableLanguages = allLanguages
                }
                return .send(.delegate(.modelSelected(modelName)))

            case let .downloadModel(modelName):
                state.downloadingModelName = modelName
                state.downloadProgress[modelName] = 0.0
                return .run { [modelClient] send in
                    do {
                        let downloadedURL = try await modelClient.downloadModel(modelName) { progress in
                            Task { await send(.downloadProgress(modelName, progress)) }
                        }
                        await send(.downloadCompleted(modelName, .success(downloadedURL)))
                    } catch {
                        await send(.downloadCompleted(modelName, .failure(error)))
                    }
                }
                .cancellable(id: "download-\(modelName)")

            case let .downloadProgress(modelName, progress):
                state.downloadProgress[modelName] = progress
                return .none

            case let .downloadCompleted(modelName, .success):
                state.downloadingModelName = nil
                state.downloadProgress.removeValue(forKey: modelName)
                return .merge(
                    .send(.fetchDownloadedModels),
                    .send(.calculateStorageUsage)
                )

            case let .downloadCompleted(modelName, .failure):
                state.downloadingModelName = nil
                state.downloadProgress.removeValue(forKey: modelName)
                return .none

            case let .deleteModelButtonTapped(modelName):
                state.modelToDelete = modelName
                return .none

            case .confirmDeleteModel:
                guard let modelName = state.modelToDelete else {
                    return .none
                }
                state.modelToDelete = nil
                return .send(.deleteModel(modelName))

            case .cancelDeleteModel:
                state.modelToDelete = nil
                return .none

            case let .deleteModel(modelName):
                return .run { send in
                    do {
                        try await modelClient.deleteModel(modelName)
                        await send(.deleteModelResponse(modelName, .success(())))
                        await send(.fetchDownloadedModels)
                        await send(.calculateStorageUsage)
                    } catch {
                        await send(.deleteModelResponse(modelName, .failure(error)))
                    }
                }

            case .deleteModelResponse:
                return .none

            // MARK: - Settings Updates

            case let .updateTranscriptionSettings(transcription):
                state.transcription = transcription
                return .send(.delegate(.transcriptionSettingsChanged(transcription)))

            case let .updateAvailableLanguages(languages):
                state.availableLanguages = languages
                return .none

            // MARK: - Storage Management

            case .calculateStorageUsage:
                return .run { [modelClient] send in
                    let usage = await modelClient.getStorageUsage()
                    await send(.storageUsageResponse(usage))
                }

            case let .storageUsageResponse(usage):
                state.storageUsage = usage
                return .none

            case .fetchModelStorageURL:
                return .run { [modelClient] send in
                    // まず保存されたブックマークを読み込む
                    if let bookmarkedURL = await modelClient.loadStorageBookmark() {
                        // ブックマークが有効な場合、そのURLを使用
                        await modelClient.setStorageLocation(bookmarkedURL)
                        await send(.modelStorageURLResponse(bookmarkedURL))
                    } else {
                        // ブックマークがない場合はデフォルトのパスを使用
                        let url = await modelClient.getModelStorageURL()
                        await send(.modelStorageURLResponse(url))
                    }
                }

            case let .modelStorageURLResponse(url):
                state.modelStorageURL = url
                // ストレージ場所が確定したら、モデル一覧を取得
                return .merge(
                    .send(.fetchModels),
                    .send(.fetchDownloadedModels),
                    .send(.calculateStorageUsage)
                )

            case .selectStorageLocation:
                return .run { send in
                    await MainActor.run {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.message = "モデルの保存先フォルダを選択してください"
                        panel.prompt = "選択"
                        if panel.runModal() == .OK, let url = panel.url {
                            Task { await send(.storageLocationSelected(.success(url))) }
                        }
                    }
                }

            case let .storageLocationSelected(.success(url)):
                // モデル関連のstateを初期化
                state.availableModels = []
                state.downloadedModels = []
                state.storageUsage = 0
                state.isLoadingModels = true
                state.modelStorageURL = url

                // ブックマークデータを同期的に作成して TranscriptionSettings に保存
                do {
                    let bookmarkData = try url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    state.transcription.storageBookmarkData = bookmarkData
                } catch {
                    // ブックマーク作成失敗はログのみ（処理は継続）
                    NSLog("Failed to create storage bookmark: \(error.localizedDescription)")
                }

                // 設定変更を親に通知してから非同期処理を開始
                let transcription = state.transcription
                return .run { [modelClient] send in
                    // 設定変更を親に通知（これにより設定が永続化される）
                    await send(.delegate(.transcriptionSettingsChanged(transcription)))

                    // WhisperKitManager のストレージ場所を更新（既存インスタンスをアンロード）
                    await modelClient.updateStorageLocation(url)

                    // 直接データを取得してレスポンスを送信
                    // 1. 利用可能モデル一覧
                    do {
                        let modelNames = try await modelClient.fetchAvailableModels()
                        let recommendedModel = await modelClient.recommendedModel()
                        var models: [WhisperModel] = []
                        for name in modelNames {
                            let isDownloaded = await modelClient.isModelDownloaded(name)
                            models.append(WhisperModel.from(
                                id: name,
                                isDownloaded: isDownloaded,
                                isRecommended: name == recommendedModel
                            ))
                        }
                        models.sort { $0.id < $1.id }
                        await send(.modelsResponse(.success(models)))
                    } catch {
                        await send(.modelsResponse(.failure(error)))
                    }

                    // 2. ダウンロード済みモデル一覧
                    do {
                        let downloadedModels = try await modelClient.fetchDownloadedModelsAsWhisperModels()
                        await send(.downloadedModelsResponse(downloadedModels))
                    } catch {
                        await send(.downloadedModelsResponse([]))
                    }

                    // 3. ストレージ使用量
                    let usage = await modelClient.getStorageUsage()
                    await send(.storageUsageResponse(usage))
                }

            case .storageLocationSelected(.failure):
                return .none

            // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Binding Helpers

extension StoreOf<ModelSettingsFeature> {
    /// Transcription Settings 用のバインディングを作成
    func bindingForTranscription<T: Equatable>(
        keyPath: WritableKeyPath<TranscriptionSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.transcription[keyPath: keyPath] },
            set: { newValue in
                var transcription = self.transcription
                transcription[keyPath: keyPath] = newValue
                self.send(.updateTranscriptionSettings(transcription))
            }
        )
    }
}
