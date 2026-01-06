//
//  TranscriptionClientTests.swift
//  WhisperPadTests
//

import ComposableArchitecture
import Dependencies
import XCTest

@testable import WhisperPad

/// TranscriptionClient のテスト
///
/// 文字起こし機能のテストを行います。
/// モデル管理テストは ModelClientTests に移動しました。
@MainActor
final class TranscriptionClientTests: XCTestCase {
    // MARK: - Test Value Tests

    /// testValue でモデル状態が loaded であることを確認
    func testModelState_testValue_returnsLoaded() async {
        let state = await withDependencies {
            $0.transcriptionClient = .testValue
        } operation: {
            @Dependency(\.transcriptionClient) var transcriptionClient
            return await transcriptionClient.modelState()
        }

        XCTAssertEqual(state, .loaded, "Model state should be loaded in test value")
    }

    /// testValue で現在のモデル名が取得できることを確認
    func testCurrentModelName_testValue_returnsName() async {
        let modelName = await withDependencies {
            $0.transcriptionClient = .testValue
        } operation: {
            @Dependency(\.transcriptionClient) var transcriptionClient
            return await transcriptionClient.currentModelName()
        }

        XCTAssertEqual(modelName, "openai_whisper-tiny")
    }

    /// testValue で文字起こしが成功することを確認
    func testTranscribe_testValue_returnsText() async throws {
        let testURL = URL(fileURLWithPath: "/tmp/test.wav")
        let text = try await withDependencies {
            $0.transcriptionClient = .testValue
        } operation: {
            @Dependency(\.transcriptionClient) var transcriptionClient
            return try await transcriptionClient.transcribe(testURL, nil)
        }

        XCTAssertFalse(text.isEmpty, "Transcription should not be empty")
        XCTAssertEqual(text, "テスト用の文字起こし結果")
    }
}

// MARK: - TranscriptionModelState Equatable Tests

extension TranscriptionClientTests {
    /// TranscriptionModelState の等価性をテスト
    func testTranscriptionModelState_equality() {
        XCTAssertEqual(TranscriptionModelState.unloaded, TranscriptionModelState.unloaded)
        XCTAssertEqual(TranscriptionModelState.loaded, TranscriptionModelState.loaded)
        XCTAssertEqual(TranscriptionModelState.loading, TranscriptionModelState.loading)
        XCTAssertEqual(
            TranscriptionModelState.downloading(progress: 0.5),
            TranscriptionModelState.downloading(progress: 0.5)
        )
        XCTAssertNotEqual(
            TranscriptionModelState.downloading(progress: 0.5),
            TranscriptionModelState.downloading(progress: 0.6)
        )
        XCTAssertEqual(
            TranscriptionModelState.error("test"),
            TranscriptionModelState.error("test")
        )
        XCTAssertNotEqual(
            TranscriptionModelState.error("test1"),
            TranscriptionModelState.error("test2")
        )
    }
}

// MARK: - TranscriptionError Tests

extension TranscriptionClientTests {
    /// TranscriptionError のローカライズされた説明をテスト
    func testTranscriptionError_localizedDescription() {
        let initError = TranscriptionError.initializationFailed("init failed")
        XCTAssertTrue(initError.errorDescription?.contains("初期化") ?? false)

        let notFoundError = TranscriptionError.modelNotFound("tiny")
        XCTAssertTrue(notFoundError.errorDescription?.contains("tiny") ?? false)

        let downloadError = TranscriptionError.modelDownloadFailed("download failed")
        XCTAssertTrue(downloadError.errorDescription?.contains("ダウンロード") ?? false)

        let loadError = TranscriptionError.modelLoadFailed("load failed")
        XCTAssertTrue(loadError.errorDescription?.contains("読み込み") ?? false)

        let transcribeError = TranscriptionError.transcriptionFailed("transcribe failed")
        XCTAssertTrue(transcribeError.errorDescription?.contains("文字起こし") ?? false)

        let audioError = TranscriptionError.audioLoadFailed("audio failed")
        XCTAssertTrue(audioError.errorDescription?.contains("音声ファイル") ?? false)

        let notLoadedError = TranscriptionError.modelNotLoaded
        XCTAssertTrue(notLoadedError.errorDescription?.contains("読み込まれていません") ?? false)

        let unknownError = TranscriptionError.unknown("unknown")
        XCTAssertTrue(unknownError.errorDescription?.contains("不明") ?? false)
    }
}

// MARK: - ModelClient Tests

extension TranscriptionClientTests {
    /// testValue でモデル一覧が取得できることを確認
    func testFetchAvailableModels_testValue_returnsModels() async throws {
        let models = try await withDependencies {
            $0.modelClient = .testValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return try await modelClient.fetchAvailableModels()
        }

        XCTAssertFalse(models.isEmpty, "Models should not be empty")
        XCTAssertTrue(
            models.contains("openai_whisper-tiny"),
            "Models should contain tiny model"
        )
    }

    /// testValue で推奨モデルが取得できることを確認
    func testRecommendedModel_testValue_returnsModel() async {
        let recommended = await withDependencies {
            $0.modelClient = .testValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return await modelClient.recommendedModel()
        }

        XCTAssertEqual(recommended, "openai_whisper-tiny")
    }

    /// testValue でモデルダウンロード済み状態を確認
    func testIsModelDownloaded_testValue_returnsTrue() async {
        let isDownloaded = await withDependencies {
            $0.modelClient = .testValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return await modelClient.isModelDownloaded("openai_whisper-tiny")
        }

        XCTAssertTrue(isDownloaded, "Model should be marked as downloaded in test value")
    }

    /// testValue でモデルダウンロードが成功することを確認
    func testDownloadModel_testValue_returnsURL() async throws {
        let url = try await withDependencies {
            $0.modelClient = .testValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return try await modelClient.downloadModel("openai_whisper-tiny", nil)
        }

        XCTAssertTrue(
            url.path.contains("openai_whisper-tiny"),
            "Downloaded URL should contain model name"
        )
    }

    /// previewValue でモデル一覧が取得できることを確認
    func testFetchAvailableModels_previewValue_returnsModels() async throws {
        let models = try await withDependencies {
            $0.modelClient = .previewValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return try await modelClient.fetchAvailableModels()
        }

        XCTAssertEqual(models.count, 3, "Preview should return 3 models")
        XCTAssertTrue(models.contains("openai_whisper-small"))
    }

    /// previewValue で推奨モデルが取得できることを確認
    func testRecommendedModel_previewValue_returnsModel() async {
        let recommended = await withDependencies {
            $0.modelClient = .previewValue
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return await modelClient.recommendedModel()
        }

        XCTAssertEqual(recommended, "openai_whisper-small")
    }

    /// カスタムモックでエラーハンドリングをテスト
    func testFetchAvailableModels_throwsError_handlesCorrectly() async {
        let expectedError = ModelClientError.fetchAvailableModelsFailed("Test error")

        do {
            _ = try await withDependencies {
                var client = ModelClient.testValue
                client.fetchAvailableModels = {
                    throw expectedError
                }
                $0.modelClient = client
            } operation: {
                @Dependency(\.modelClient) var modelClient
                return try await modelClient.fetchAvailableModels()
            }
            XCTFail("Should have thrown an error")
        } catch let error as ModelClientError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// カスタムモックでダウンロード進捗をテスト
    func testDownloadModel_reportsProgress() async throws {
        var progressValues: [Double] = []

        _ = try await withDependencies {
            var client = ModelClient.testValue
            client.downloadModel = { _, progressHandler in
                for step in 0 ... 10 {
                    progressHandler?(Double(step) / 10.0)
                }
                return URL(fileURLWithPath: "/tmp/test-model")
            }
            $0.modelClient = client
        } operation: {
            @Dependency(\.modelClient) var modelClient
            return try await modelClient.downloadModel("test-model") { progress in
                progressValues.append(progress)
            }
        }

        XCTAssertEqual(progressValues.count, 11, "Should report 11 progress updates")
        XCTAssertEqual(progressValues.first, 0.0, "First progress should be 0")
        XCTAssertEqual(progressValues.last, 1.0, "Last progress should be 1")
    }
}
