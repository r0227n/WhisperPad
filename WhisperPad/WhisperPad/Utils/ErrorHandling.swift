//
//  ErrorHandling.swift
//  WhisperPad
//

import Foundation

// MARK: - Generic Error Mapping

/// エラーを指定された型にマッピングするヘルパー関数
///
/// キャストに成功した場合はそのエラーを返し、失敗した場合はフォールバックエラーを生成します。
///
/// - Parameters:
///   - error: 元のエラー
///   - fallback: キャストに失敗した場合のフォールバックエラーを生成するクロージャ
/// - Returns: 指定された型のエラー
///
/// ## 使用例
/// ```swift
/// let recordingError = mapError(error) { RecordingError.recordingFailed($0) }
/// ```
func mapError<E: Error>(
    _ error: Error,
    fallback: (String) -> E
) -> E {
    (error as? E) ?? fallback(error.localizedDescription)
}
