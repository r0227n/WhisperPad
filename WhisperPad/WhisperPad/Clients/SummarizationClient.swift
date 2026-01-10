//
//  SummarizationClient.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "SummarizationClient")

// MARK: - SummarizationError

/// 要約関連のエラー型
enum SummarizationError: Error, Equatable, Sendable, LocalizedError {
    /// 要約機能が利用できない
    case notAvailable

    /// 要約処理に失敗
    case summarizationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            "Apple Intelligence要約機能は現在のデバイスで利用できません。"
        case let .summarizationFailed(message):
            "要約処理に失敗しました: \(message)"
        }
    }
}

// MARK: - SummarizationClient

/// 要約クライアント
///
/// Apple Intelligence Foundation Modelsを使用してテキストを要約します。
/// macOS 26以上で利用可能です。
struct SummarizationClient: Sendable {
    /// テキストを要約
    /// - Parameter text: 要約するテキスト
    /// - Returns: 要約されたテキスト
    /// - Throws: 要約に失敗した場合は SummarizationError
    var summarize: @Sendable (_ text: String) async throws -> String

    /// 要約機能が利用可能かどうか
    /// - Returns: 利用可能な場合は true
    var isAvailable: @Sendable () -> Bool
}

// MARK: - DependencyKey

extension SummarizationClient: DependencyKey {
    static var liveValue: Self {
        if #available(macOS 26, *) {
            return .liveImplementation
        } else {
            return Self(
                summarize: { text in
                    clientLogger.warning("Summarization not available on this macOS version")
                    throw SummarizationError.notAvailable
                },
                isAvailable: { false }
            )
        }
    }
}

// MARK: - TestDependencyKey

extension SummarizationClient: TestDependencyKey {
    static var previewValue: Self {
        Self(
            summarize: { text in
                clientLogger.debug("[DEBUG] previewValue.summarize called!")
                // プレビュー用: テキストの最初の100文字を返す
                let preview = String(text.prefix(100))
                return "[要約] \(preview)..."
            },
            isAvailable: { true }
        )
    }

    static var testValue: Self {
        Self(
            summarize: { text in
                clientLogger.debug("[DEBUG] testValue.summarize called!")
                return text
            },
            isAvailable: { true }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var summarizationClient: SummarizationClient {
        get { self[SummarizationClient.self] }
        set { self[SummarizationClient.self] = newValue }
    }
}

// MARK: - Live Implementation (macOS 26+)

#if compiler(>=6.0)
@available(macOS 26, *)
import FoundationModels

@available(macOS 26, *)
extension SummarizationClient {
    static let liveImplementation = Self(
        summarize: { text in
            clientLogger.info("Starting summarization with Foundation Models")

            do {
                let session = LanguageModelSession()
                let prompt = """
                以下の文字起こしテキストを簡潔に要約してください。
                重要なポイントを保持しながら、読みやすい形式でまとめてください。

                ---
                \(text)
                ---

                要約:
                """
                let response = try await session.respond(to: prompt)
                clientLogger.info("Summarization completed successfully")
                return response.content
            } catch {
                clientLogger.error("Summarization failed: \(error.localizedDescription)")
                throw SummarizationError.summarizationFailed(error.localizedDescription)
            }
        },
        isAvailable: {
            // Apple Intelligenceが利用可能かチェック
            if #available(macOS 26, *) {
                return LanguageModel.isAvailable
            }
            return false
        }
    )
}
#endif
