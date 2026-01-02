//
//  LocalizedStringKey.swift
//  WhisperPad
//

import Foundation

// swiftlint:disable file_length type_body_length

/// All localized string keys for the application
enum LocalizedStringKey: Sendable {
    // MARK: - Settings Tabs

    case settingsTabGeneral
    case settingsTabIcon
    case settingsTabHotkey
    case settingsTabRecording
    case settingsTabModel

    // MARK: - General Settings Tab

    case generalLaunchAtLogin
    case generalLaunchAtLoginDescription
    case generalBehavior
    case generalShowNotification
    case generalShowNotificationDescription
    case generalPlaySound
    case generalPlaySoundDescription
    case generalNotificationSettings
    case generalCustomize
    case generalNotification
    case generalNotificationSectionDescription
    case generalLanguage
    case generalLanguageDescription

    // MARK: - Recording Settings Tab

    case recordingInputDevice
    case recordingInputDeviceDescription
    case recordingSystemDefault
    case recordingOutput
    case recordingCopyToClipboard
    case recordingCopyToClipboardDescription
    case recordingCopyToClipboardToggleDescription
    case recordingSaveToFile
    case recordingSettings
    case recordingPasteDescription
    case recordingAutoStopOnSilence
    case recordingAutoStopDescription
    case recordingSilenceDetection
    case recordingSilenceDuration
    case recordingSeconds
    case recordingSilenceThreshold
    case recordingDecibels
    case recordingSilenceDescription

    // MARK: - Hotkey Settings Tab

    case hotkeySelectShortcut
    case hotkeyDescription
    case hotkeyShortcutKey
    case hotkeyConflictWarning

    // MARK: - Icon Settings Tab

    case iconStatus
    case iconMenuBarIcon
    case iconResetState
    case iconDescription
    case iconSection
    case iconColor

    // MARK: - Model Settings Tab

    case modelDeleteConfirmTitle
    case modelDelete
    case modelCancel
    case modelDeleteConfirmMessage
    case modelActiveModel
    case modelModel
    case modelDownloadPrompt
    case modelRecommended
    case modelLanguage
    case modelAvailableModels
    case modelLoading
    case modelNoMatches
    case modelResetFilter
    case modelStorage
    case modelUsage
    case modelSaveLocation
    case modelDefault
    case modelChange
    case modelReset
    case modelStorageDescription

    // MARK: - File Output Popover

    case fileOutputTitle
    case fileOutputSaveLocation
    case fileOutputChange
    case fileOutputChangeSaveLocation
    case fileOutputFileNameFormat
    case fileOutputDateTimeFormat
    case fileOutputTimestampFormat
    case fileOutputSequentialFormat
    case fileOutputFileFormat
    case fileOutputIncludeMetadata
    case fileOutputMetadataDescription
    case fileOutputDescription
    case fileOutputSelectFolder
    case fileOutputSelect

    // MARK: - Notification Popover

    case notificationMessage
    case notificationTitle
    case notificationTitlePlaceholder
    case notificationCompletionMessage
    case notificationOnRegularCompletion
    case notificationStreamingMessage
    case notificationOnStreamingCompletion
    case notificationResetToDefault
    case notificationDefaultTitle
    case notificationDefaultMessage
    case notificationDefaultStreamingMessage
    case notificationResetDescription

    // MARK: - Shortcut Key Button

    case shortcutEnterKey
    case shortcutCancel
    case shortcutResetToDefault
    case shortcutAccessibilityLabel

    // MARK: - Model List Row

    case modelRowDownloaded
    case modelRowNotDownloaded
    case modelRowRecommended
    case modelRowEnglishOnly
    case modelRowDelete
    case modelRowDownload
    case modelRowDeleteModel
    case modelRowDeleteDescription
    case modelRowDownloadModel
    case modelRowDownloadDescription
    case modelRowEnglishOnlyLabel
    case modelRowDownloadProgress
    case modelRowPercent

    // MARK: - Model Search Filter Bar

    case modelSearchPlaceholder
    case modelSearchClear
    case modelSearchStatus

    // MARK: - Hotkey Recorder

    case hotkeyRecorderEnterKey
    case hotkeyRecorderCancel
    case hotkeyRecorderCancelDescription
    case hotkeyRecorderClear
    case hotkeyRecorderResetDescription
    case hotkeyRecorderClickToChange

    // MARK: - Symbol Picker

    case symbolPickerMore
    case symbolPickerSelectIcon
    case symbolPickerClose
    case symbolPickerSelected

    // MARK: - Streaming Transcription View

    case streamingStopConfirmTitle
    case streamingContinue
    case streamingStopAndClose
    case streamingStopConfirmMessage
    case streamingElapsedTime
    case streamingClose
    case streamingStatusIdle
    case streamingStatusInitializing
    case streamingStatusRecording
    case streamingStatusProcessing
    case streamingStatusCompleted
    case streamingStatusError
    case streamingColorGray
    case streamingColorYellow
    case streamingColorRed
    case streamingColorBlue
    case streamingColorGreen
    case streamingColorOrange
    case streamingNoTranscription
    case streamingTranscriptionPrefix
    case streamingTokensPerSecond
    case streamingStop
    case streamingStopRecording
    case streamingProcessing
    case streamingSaveToFile
    case streamingSaveDescription
    case streamingCopyAndClose
    case streamingCopyDescription

    // MARK: - Icon Config Status

    case iconStatusIdle
    case iconStatusRecording
    case iconStatusPaused
    case iconStatusTranscribing
    case iconStatusCompleted
    case iconStatusStreamingTranscribing
    case iconStatusStreamingCompleted
    case iconStatusError
    case iconStatusCancel

    case iconStatusIdleDescription
    case iconStatusRecordingDescription
    case iconStatusPausedDescription
    case iconStatusTranscribingDescription
    case iconStatusCompletedDescription
    case iconStatusStreamingTranscribingDescription
    case iconStatusStreamingCompletedDescription
    case iconStatusErrorDescription
    case iconStatusCancelDescription

    // MARK: - Transcription Language

    case transcriptionLanguageAuto
    case transcriptionLanguageJapanese
    case transcriptionLanguageEnglish
    case transcriptionLanguageChinese
    case transcriptionLanguageKorean
    case transcriptionLanguageFrench
    case transcriptionLanguageGerman
    case transcriptionLanguageSpanish

    // MARK: - Hotkey Types

    case hotkeyTypeRecording
    case hotkeyTypePause
    case hotkeyTypeCancel
    case hotkeyTypeStreaming
    case hotkeyTypeCopyAndClose
    case hotkeyTypeSaveToFile
    case hotkeyTypeClose

    case hotkeyTypeRecordingDescription
    case hotkeyTypePauseDescription
    case hotkeyTypeCancelDescription
    case hotkeyTypeStreamingDescription
    case hotkeyTypeCopyAndCloseDescription
    case hotkeyTypeSaveToFileDescription
    case hotkeyTypeCloseDescription

    // MARK: - Hotkey Categories

    case hotkeyCategoryRecording
    case hotkeyCategoryCancel
    case hotkeyCategoryPopup

    // MARK: - Model Filter

    case modelFilterAll
    case modelFilterDownloaded
    case modelFilterNotDownloaded

    // MARK: - Recording Errors

    case errorMicrophonePermission
    case errorRecordingFailed
    case errorNoRecordingURL
    case errorAudioSessionSetup
    case errorAudioFileCreation
    case errorSegmentMerge

    // MARK: - Transcription Errors

    case errorWhisperKitInit
    case errorModelNotFound
    case errorModelDownload
    case errorModelLoad
    case errorTranscription
    case errorAudioLoad
    case errorModelNotLoaded
    case errorUnknown

    /// Returns localized string for the given language
    func localized(for language: AppLanguage) -> String {
        switch language {
        case .english:
            englishString
        case .japanese:
            japaneseString
        }
    }
}

// MARK: - English Strings

extension LocalizedStringKey {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    var englishString: String {
        switch self {
        // Settings Tabs
        case .settingsTabGeneral: "General"
        case .settingsTabIcon: "Icon"
        case .settingsTabHotkey: "Shortcuts"
        case .settingsTabRecording: "Recording"
        case .settingsTabModel: "Model"

        // General Settings Tab
        case .generalLaunchAtLogin: "Launch at Login"
        case .generalLaunchAtLoginDescription: "Automatically launch the app when macOS starts"
        case .generalBehavior: "Behavior"
        case .generalShowNotification: "Show Notification"
        case .generalShowNotificationDescription: "Show notification in Notification Center when transcription completes"
        case .generalPlaySound: "Play Sound"
        case .generalPlaySoundDescription: "Play sound when transcription completes"
        case .generalNotificationSettings: "Notification Message Settings"
        case .generalCustomize: "Customize"
        case .generalNotification: "Notification"
        case .generalNotificationSectionDescription: "Configure notification and sound on transcription completion"
        case .generalLanguage: "Language"
        case .generalLanguageDescription: "Select the display language for the app"

        // Recording Settings Tab
        case .recordingInputDevice: "Input Device"
        case .recordingInputDeviceDescription: "Select the microphone for recording"
        case .recordingSystemDefault: "System Default"
        case .recordingOutput: "Output"
        case .recordingCopyToClipboard: "Copy to Clipboard"
        case .recordingCopyToClipboardDescription: "Copy transcription result to clipboard"
        case .recordingCopyToClipboardToggleDescription: "Enable to copy transcription result to clipboard"
        case .recordingSaveToFile: "Save to File"
        case .recordingSettings: "Settings"
        case .recordingPasteDescription: "Paste transcription anywhere after completion"
        case .recordingAutoStopOnSilence: "Auto-stop on Silence"
        case .recordingAutoStopDescription: "Automatically stop recording after silence duration"
        case .recordingSilenceDetection: "Silence Detection"
        case .recordingSilenceDuration: "Silence Duration"
        case .recordingSeconds: "seconds"
        case .recordingSilenceThreshold: "Silence Threshold"
        case .recordingDecibels: "dB"
        case .recordingSilenceDescription: "Stop recording when audio level is below threshold for specified duration"

        // Hotkey Settings Tab
        case .hotkeySelectShortcut: "Select a shortcut"
        case .hotkeyDescription: "Description"
        case .hotkeyShortcutKey: "Shortcut Key"
        case .hotkeyConflictWarning: "Change if conflicts with other apps"

        // Icon Settings Tab
        case .iconStatus: "Icon Status"
        case .iconMenuBarIcon: "Menu Bar Icon"
        case .iconResetState: "Reset this state"
        case .iconDescription: "Description"
        case .iconSection: "Icon"
        case .iconColor: "Color"

        // Model Settings Tab
        case .modelDeleteConfirmTitle: "Delete model?"
        case .modelDelete: "Delete"
        case .modelCancel: "Cancel"
        case .modelDeleteConfirmMessage: "will be deleted. Download again to use."
        case .modelActiveModel: "Active Model"
        case .modelModel: "Model"
        case .modelDownloadPrompt: "Please download a model"
        case .modelRecommended: "Recommended"
        case .modelLanguage: "Language"
        case .modelAvailableModels: "Available Models"
        case .modelLoading: "Loading models..."
        case .modelNoMatches: "No models match criteria"
        case .modelResetFilter: "Reset Filter"
        case .modelStorage: "Storage"
        case .modelUsage: "Usage"
        case .modelSaveLocation: "Save Location"
        case .modelDefault: "Default"
        case .modelChange: "Change..."
        case .modelReset: "Reset"
        case .modelStorageDescription: "Models are stored on device and work offline"

        // File Output Popover
        case .fileOutputTitle: "File Output Settings"
        case .fileOutputSaveLocation: "Save Location"
        case .fileOutputChange: "Change..."
        case .fileOutputChangeSaveLocation: "Change save location"
        case .fileOutputFileNameFormat: "File Name Format"
        case .fileOutputDateTimeFormat: "DateTime (WhisperPad_20241201_143052)"
        case .fileOutputTimestampFormat: "Timestamp (WhisperPad_1701415852)"
        case .fileOutputSequentialFormat: "Sequential (WhisperPad_001)"
        case .fileOutputFileFormat: "File Format"
        case .fileOutputIncludeMetadata: "Include Metadata"
        case .fileOutputMetadataDescription: "Include creation date and app info in file"
        case .fileOutputDescription: "Save transcription result as text file"
        case .fileOutputSelectFolder: "Select output folder"
        case .fileOutputSelect: "Select"

        // Notification Popover
        case .notificationMessage: "Notification Message"
        case .notificationTitle: "Title"
        case .notificationTitlePlaceholder: "Notification Title"
        case .notificationCompletionMessage: "Completion Message"
        case .notificationOnRegularCompletion: "On regular transcription completion"
        case .notificationStreamingMessage: "Streaming Completion Message"
        case .notificationOnStreamingCompletion: "On streaming transcription completion"
        case .notificationResetToDefault: "Reset to Default"
        case .notificationDefaultTitle: "WhisperPad"
        case .notificationDefaultMessage: "Transcription completed"
        case .notificationDefaultStreamingMessage: "Streaming transcription completed"
        case .notificationResetDescription: "Reset notification settings to defaults"

        // Shortcut Key Button
        case .shortcutEnterKey: "Enter key..."
        case .shortcutCancel: "Cancel"
        case .shortcutResetToDefault: "Reset to Default"
        case .shortcutAccessibilityLabel: "Shortcut. Click to change, right-click for options"

        // Model List Row
        case .modelRowDownloaded: "Downloaded"
        case .modelRowNotDownloaded: "Not Downloaded"
        case .modelRowRecommended: "Recommended"
        case .modelRowEnglishOnly: "EN"
        case .modelRowDelete: "Delete"
        case .modelRowDownload: "Download"
        case .modelRowDeleteModel: "Delete model"
        case .modelRowDeleteDescription: "Delete model. Download again to use"
        case .modelRowDownloadModel: "Download model"
        case .modelRowDownloadDescription: "Download model for offline use"
        case .modelRowEnglishOnlyLabel: "English only"
        case .modelRowDownloadProgress: "Download progress"
        case .modelRowPercent: "percent"

        // Model Search Filter Bar
        case .modelSearchPlaceholder: "Search models..."
        case .modelSearchClear: "Clear search"
        case .modelSearchStatus: "Status"

        // Hotkey Recorder
        case .hotkeyRecorderEnterKey: "Enter key..."
        case .hotkeyRecorderCancel: "Cancel"
        case .hotkeyRecorderCancelDescription: "Cancel hotkey input"
        case .hotkeyRecorderClear: "Clear"
        case .hotkeyRecorderResetDescription: "Reset hotkey to default"
        case .hotkeyRecorderClickToChange: "Click to change"

        // Symbol Picker
        case .symbolPickerMore: "More symbols..."
        case .symbolPickerSelectIcon: "Select Icon"
        case .symbolPickerClose: "Close"
        case .symbolPickerSelected: "Selected:"

        // Streaming Transcription View
        case .streamingStopConfirmTitle: "Stop recording?"
        case .streamingContinue: "Continue"
        case .streamingStopAndClose: "Stop and Close"
        case .streamingStopConfirmMessage: "Recording data will be discarded."
        case .streamingElapsedTime: "Elapsed Time"
        case .streamingClose: "Close"
        case .streamingStatusIdle: "Idle"
        case .streamingStatusInitializing: "Initializing"
        case .streamingStatusRecording: "Recording"
        case .streamingStatusProcessing: "Processing"
        case .streamingStatusCompleted: "Completed"
        case .streamingStatusError: "Error"
        case .streamingColorGray: "Gray"
        case .streamingColorYellow: "Yellow"
        case .streamingColorRed: "Red"
        case .streamingColorBlue: "Blue"
        case .streamingColorGreen: "Green"
        case .streamingColorOrange: "Orange"
        case .streamingNoTranscription: "No transcription text"
        case .streamingTranscriptionPrefix: "Transcription: "
        case .streamingTokensPerSecond: "tok/s"
        case .streamingStop: "Stop"
        case .streamingStopRecording: "Stop recording"
        case .streamingProcessing: "Processing..."
        case .streamingSaveToFile: "Save to File"
        case .streamingSaveDescription: "Save transcription to file"
        case .streamingCopyAndClose: "Copy and Close"
        case .streamingCopyDescription: "Copy transcription to clipboard and close window"

        // Icon Config Status
        case .iconStatusIdle: "Idle"
        case .iconStatusRecording: "Recording"
        case .iconStatusPaused: "Paused"
        case .iconStatusTranscribing: "Transcribing"
        case .iconStatusCompleted: "Completed"
        case .iconStatusStreamingTranscribing: "Streaming"
        case .iconStatusStreamingCompleted: "Streaming Completed"
        case .iconStatusError: "Error"
        case .iconStatusCancel: "Cancel"
        case .iconStatusIdleDescription:
            "Waiting for operation. Click menu bar icon or press shortcut to start."
        case .iconStatusRecordingDescription:
            "Recording audio. Speak into the microphone."
        case .iconStatusPausedDescription:
            "Recording paused. Press shortcut again to resume."
        case .iconStatusTranscribingDescription:
            "Converting speech to text. Please wait."
        case .iconStatusCompletedDescription:
            "Transcription complete. Text copied to clipboard or saved to file."
        case .iconStatusStreamingTranscribingDescription:
            "Real-time transcription in progress. Text appears as you speak."
        case .iconStatusStreamingCompletedDescription:
            "Streaming transcription complete."
        case .iconStatusErrorDescription:
            "An error occurred. Check settings or try again."
        case .iconStatusCancelDescription:
            "Operation cancelled."

        // Transcription Language
        case .transcriptionLanguageAuto: "Auto Detect"
        case .transcriptionLanguageJapanese: "日本語"
        case .transcriptionLanguageEnglish: "English"
        case .transcriptionLanguageChinese: "中文"
        case .transcriptionLanguageKorean: "한국어"
        case .transcriptionLanguageFrench: "Français"
        case .transcriptionLanguageGerman: "Deutsch"
        case .transcriptionLanguageSpanish: "Español"

        // Hotkey Types
        case .hotkeyTypeRecording: "Start/Stop Recording"
        case .hotkeyTypePause: "Pause/Resume"
        case .hotkeyTypeCancel: "Cancel Recording"
        case .hotkeyTypeStreaming: "Streaming"
        case .hotkeyTypeCopyAndClose: "Copy and Close"
        case .hotkeyTypeSaveToFile: "Save to File"
        case .hotkeyTypeClose: "Close"
        case .hotkeyTypeRecordingDescription: "Start or stop recording"
        case .hotkeyTypePauseDescription: "Pause or resume recording"
        case .hotkeyTypeCancelDescription: "Cancel recording in progress"
        case .hotkeyTypeStreamingDescription: "Start real-time transcription"
        case .hotkeyTypeCopyAndCloseDescription: "Copy transcription to clipboard and close popup"
        case .hotkeyTypeSaveToFileDescription: "Save transcription to file"
        case .hotkeyTypeCloseDescription: "Close popup"

        // Hotkey Categories
        case .hotkeyCategoryRecording: "Recording"
        case .hotkeyCategoryCancel: "Cancel"
        case .hotkeyCategoryPopup: "Popup"

        // Model Filter
        case .modelFilterAll: "All"
        case .modelFilterDownloaded: "Downloaded"
        case .modelFilterNotDownloaded: "Not Downloaded"

        // Recording Errors
        case .errorMicrophonePermission:
            "Microphone access denied. Please allow microphone permission in System Preferences."
        case .errorRecordingFailed: "Recording failed"
        case .errorNoRecordingURL: "Recording file URL not set."
        case .errorAudioSessionSetup: "Audio session setup failed."
        case .errorAudioFileCreation: "Audio file creation failed"
        case .errorSegmentMerge: "Audio segment merge failed"

        // Transcription Errors
        case .errorWhisperKitInit: "WhisperKit initialization failed"
        case .errorModelNotFound: "not found"
        case .errorModelDownload: "Model download failed"
        case .errorModelLoad: "Model load failed"
        case .errorTranscription: "Transcription failed"
        case .errorAudioLoad: "Audio file load failed"
        case .errorModelNotLoaded: "Model not loaded. Please download a model first."
        case .errorUnknown: "Unknown error"
        }
    }
}

// MARK: - Japanese Strings

extension LocalizedStringKey {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    var japaneseString: String {
        switch self {
        // Settings Tabs
        case .settingsTabGeneral: "一般"
        case .settingsTabIcon: "アイコン"
        case .settingsTabHotkey: "ショートカット"
        case .settingsTabRecording: "録音"
        case .settingsTabModel: "モデル"

        // General Settings Tab
        case .generalLaunchAtLogin: "ログイン時に起動"
        case .generalLaunchAtLoginDescription: "macOS 起動時にアプリを自動的に起動します"
        case .generalBehavior: "動作"
        case .generalShowNotification: "通知を表示"
        case .generalShowNotificationDescription: "文字起こし完了時に通知センターに通知を表示します"
        case .generalPlaySound: "サウンドを再生"
        case .generalPlaySoundDescription: "文字起こし完了時にサウンドを再生します"
        case .generalNotificationSettings: "メッセージ設定"
        case .generalCustomize: "カスタマイズ"
        case .generalNotification: "通知"
        case .generalNotificationSectionDescription: "文字起こし完了時の通知とサウンドを設定します"
        case .generalLanguage: "言語"
        case .generalLanguageDescription: "アプリの表示言語を選択します"

        // Recording Settings Tab
        case .recordingInputDevice: "入力デバイス"
        case .recordingInputDeviceDescription: "録音に使用するマイクを選択します"
        case .recordingSystemDefault: "システムデフォルト"
        case .recordingOutput: "出力"
        case .recordingCopyToClipboard: "クリップボードにコピー"
        case .recordingCopyToClipboardDescription: "文字起こし結果をクリップボードにコピーします"
        case .recordingCopyToClipboardToggleDescription: "オンにすると文字起こし結果をクリップボードにコピーします"
        case .recordingSaveToFile: "ファイルに保存"
        case .recordingSettings: "設定"
        case .recordingPasteDescription: "文字起こし完了後、すぐに他のアプリにペーストできます"
        case .recordingAutoStopOnSilence: "無音検出で自動停止"
        case .recordingAutoStopDescription: "一定時間無音が続くと録音を自動停止します"
        case .recordingSilenceDetection: "無音検出"
        case .recordingSilenceDuration: "無音判定時間"
        case .recordingSeconds: "秒"
        case .recordingSilenceThreshold: "無音判定しきい値"
        case .recordingDecibels: "dB"
        case .recordingSilenceDescription: "指定した時間、音声レベルがしきい値を下回ると録音を停止します"

        // Hotkey Settings Tab
        case .hotkeySelectShortcut: "ショートカットを選択してください"
        case .hotkeyDescription: "説明"
        case .hotkeyShortcutKey: "ショートカットキー"
        case .hotkeyConflictWarning: "他のアプリと競合する場合は変更してください"

        // Icon Settings Tab
        case .iconStatus: "アイコン状態"
        case .iconMenuBarIcon: "メニューバーアイコン"
        case .iconResetState: "この状態をリセット"
        case .iconDescription: "説明"
        case .iconSection: "アイコン"
        case .iconColor: "色"

        // Model Settings Tab
        case .modelDeleteConfirmTitle: "モデルを削除しますか？"
        case .modelDelete: "削除"
        case .modelCancel: "キャンセル"
        case .modelDeleteConfirmMessage: "を削除します。再度使用するにはダウンロードが必要です。"
        case .modelActiveModel: "使用中のモデル"
        case .modelModel: "モデル"
        case .modelDownloadPrompt: "モデルをダウンロードしてください"
        case .modelRecommended: "推奨"
        case .modelLanguage: "言語"
        case .modelAvailableModels: "利用可能なモデル"
        case .modelLoading: "モデル一覧を取得中..."
        case .modelNoMatches: "条件に一致するモデルがありません"
        case .modelResetFilter: "フィルターをリセット"
        case .modelStorage: "ストレージ"
        case .modelUsage: "使用量"
        case .modelSaveLocation: "保存先"
        case .modelDefault: "デフォルト"
        case .modelChange: "変更..."
        case .modelReset: "リセット"
        case .modelStorageDescription: "モデルはデバイス上に保存され、オフラインで使用できます"

        // File Output Popover
        case .fileOutputTitle: "ファイル出力設定"
        case .fileOutputSaveLocation: "保存先"
        case .fileOutputChange: "変更..."
        case .fileOutputChangeSaveLocation: "保存先を変更"
        case .fileOutputFileNameFormat: "ファイル名形式"
        case .fileOutputDateTimeFormat: "日時 (WhisperPad_20241201_143052)"
        case .fileOutputTimestampFormat: "タイムスタンプ (WhisperPad_1701415852)"
        case .fileOutputSequentialFormat: "連番 (WhisperPad_001)"
        case .fileOutputFileFormat: "ファイル形式"
        case .fileOutputIncludeMetadata: "メタデータを含める"
        case .fileOutputMetadataDescription: "ファイルに作成日時やアプリ情報を含めます"
        case .fileOutputDescription: "文字起こし結果をテキストファイルとして保存します"
        case .fileOutputSelectFolder: "ファイルの保存先フォルダを選択してください"
        case .fileOutputSelect: "選択"

        // Notification Popover
        case .notificationMessage: "通知メッセージ"
        case .notificationTitle: "タイトル"
        case .notificationTitlePlaceholder: "通知タイトル"
        case .notificationCompletionMessage: "完了メッセージ"
        case .notificationOnRegularCompletion: "通常録音完了時"
        case .notificationStreamingMessage: "リアルタイム完了メッセージ"
        case .notificationOnStreamingCompletion: "リアルタイム文字起こし完了時"
        case .notificationResetToDefault: "デフォルトに戻す"
        case .notificationDefaultTitle: "WhisperPad"
        case .notificationDefaultMessage: "文字起こしが完了しました"
        case .notificationDefaultStreamingMessage: "リアルタイム文字起こしが完了しました"
        case .notificationResetDescription: "通知設定を初期値に戻します"

        // Shortcut Key Button
        case .shortcutEnterKey: "キーを入力..."
        case .shortcutCancel: "キャンセル"
        case .shortcutResetToDefault: "デフォルトに戻す"
        case .shortcutAccessibilityLabel: "ショートカット。クリックして変更、右クリックでオプション"

        // Model List Row
        case .modelRowDownloaded: "ダウンロード済み"
        case .modelRowNotDownloaded: "未ダウンロード"
        case .modelRowRecommended: "推奨"
        case .modelRowEnglishOnly: "EN"
        case .modelRowDelete: "削除"
        case .modelRowDownload: "ダウンロード"
        case .modelRowDeleteModel: "モデルを削除"
        case .modelRowDeleteDescription: "モデルを削除します。再度使用するにはダウンロードが必要です"
        case .modelRowDownloadModel: "モデルをダウンロード"
        case .modelRowDownloadDescription: "モデルをダウンロードしてオフラインで使用できるようにします"
        case .modelRowEnglishOnlyLabel: "英語専用"
        case .modelRowDownloadProgress: "ダウンロード進捗"
        case .modelRowPercent: "パーセント"

        // Model Search Filter Bar
        case .modelSearchPlaceholder: "モデルを検索..."
        case .modelSearchClear: "検索をクリア"
        case .modelSearchStatus: "状態"

        // Hotkey Recorder
        case .hotkeyRecorderEnterKey: "キーを入力..."
        case .hotkeyRecorderCancel: "キャンセル"
        case .hotkeyRecorderCancelDescription: "ホットキーの入力をキャンセルします"
        case .hotkeyRecorderClear: "クリア"
        case .hotkeyRecorderResetDescription: "ホットキーをデフォルトに戻します"
        case .hotkeyRecorderClickToChange: "クリックして変更"

        // Symbol Picker
        case .symbolPickerMore: "その他のシンボル..."
        case .symbolPickerSelectIcon: "アイコンを選択"
        case .symbolPickerClose: "閉じる"
        case .symbolPickerSelected: "選択中:"

        // Streaming Transcription View
        case .streamingStopConfirmTitle: "録音を中止しますか？"
        case .streamingContinue: "続ける"
        case .streamingStopAndClose: "中止して閉じる"
        case .streamingStopConfirmMessage: "録音中のデータは破棄されます。"
        case .streamingElapsedTime: "経過時間"
        case .streamingClose: "閉じる"
        case .streamingStatusIdle: "待機中"
        case .streamingStatusInitializing: "初期化中"
        case .streamingStatusRecording: "録音中"
        case .streamingStatusProcessing: "処理中"
        case .streamingStatusCompleted: "完了"
        case .streamingStatusError: "エラー"
        case .streamingColorGray: "グレー"
        case .streamingColorYellow: "黄色"
        case .streamingColorRed: "赤"
        case .streamingColorBlue: "青"
        case .streamingColorGreen: "緑"
        case .streamingColorOrange: "オレンジ"
        case .streamingNoTranscription: "文字起こしテキストなし"
        case .streamingTranscriptionPrefix: "文字起こし: "
        case .streamingTokensPerSecond: "tok/s"
        case .streamingStop: "停止"
        case .streamingStopRecording: "録音を停止します"
        case .streamingProcessing: "処理中..."
        case .streamingSaveToFile: "ファイル保存"
        case .streamingSaveDescription: "文字起こしをファイルに保存します"
        case .streamingCopyAndClose: "コピーして閉じる"
        case .streamingCopyDescription: "文字起こしをクリップボードにコピーしてウィンドウを閉じます"

        // Icon Config Status
        case .iconStatusIdle: "待機中"
        case .iconStatusRecording: "録音中"
        case .iconStatusPaused: "一時停止中"
        case .iconStatusTranscribing: "文字起こし中"
        case .iconStatusCompleted: "完了"
        case .iconStatusStreamingTranscribing: "ストリーミング中"
        case .iconStatusStreamingCompleted: "ストリーミング完了"
        case .iconStatusError: "エラー"
        case .iconStatusCancel: "キャンセル"
        case .iconStatusIdleDescription:
            "操作を待機しています。メニューバーアイコンをクリックするか、ショートカットキーを押して開始できます。"
        case .iconStatusRecordingDescription:
            "音声を録音しています。マイクに向かって話してください。"
        case .iconStatusPausedDescription:
            "録音が一時停止しています。ショートカットキーを押すと再開します。"
        case .iconStatusTranscribingDescription:
            "音声をテキストに変換しています。しばらくお待ちください。"
        case .iconStatusCompletedDescription:
            "文字起こしが完了しました。テキストはクリップボードにコピーされるか、ファイルに保存されます。"
        case .iconStatusStreamingTranscribingDescription:
            "リアルタイムで文字起こしを行っています。話すとすぐにテキストが表示されます。"
        case .iconStatusStreamingCompletedDescription:
            "リアルタイム文字起こしが完了しました。"
        case .iconStatusErrorDescription:
            "エラーが発生しました。設定を確認するか、再試行してください。"
        case .iconStatusCancelDescription:
            "操作がキャンセルされました。"

        // Transcription Language
        case .transcriptionLanguageAuto: "自動検出"
        case .transcriptionLanguageJapanese: "日本語"
        case .transcriptionLanguageEnglish: "English"
        case .transcriptionLanguageChinese: "中文"
        case .transcriptionLanguageKorean: "한국어"
        case .transcriptionLanguageFrench: "Français"
        case .transcriptionLanguageGerman: "Deutsch"
        case .transcriptionLanguageSpanish: "Español"

        // Hotkey Types
        case .hotkeyTypeRecording: "録音開始/停止"
        case .hotkeyTypePause: "一時停止/再開"
        case .hotkeyTypeCancel: "録音キャンセル"
        case .hotkeyTypeStreaming: "ストリーミング"
        case .hotkeyTypeCopyAndClose: "コピーして閉じる"
        case .hotkeyTypeSaveToFile: "ファイル保存"
        case .hotkeyTypeClose: "閉じる"
        case .hotkeyTypeRecordingDescription: "録音を開始または停止します"
        case .hotkeyTypePauseDescription: "録音を一時停止または再開します"
        case .hotkeyTypeCancelDescription: "進行中の録音をキャンセルします"
        case .hotkeyTypeStreamingDescription: "リアルタイム文字起こしを開始します"
        case .hotkeyTypeCopyAndCloseDescription: "文字起こしをクリップボードにコピーしてポップアップを閉じます"
        case .hotkeyTypeSaveToFileDescription: "文字起こしをファイルに保存します"
        case .hotkeyTypeCloseDescription: "ポップアップを閉じます"

        // Hotkey Categories
        case .hotkeyCategoryRecording: "録音"
        case .hotkeyCategoryCancel: "キャンセル"
        case .hotkeyCategoryPopup: "ポップアップ"

        // Model Filter
        case .modelFilterAll: "すべて"
        case .modelFilterDownloaded: "ダウンロード済み"
        case .modelFilterNotDownloaded: "未ダウンロード"

        // Recording Errors
        case .errorMicrophonePermission:
            "マイクへのアクセスが許可されていません。システム環境設定でマイクの権限を許可してください。"
        case .errorRecordingFailed: "録音の開始に失敗しました"
        case .errorNoRecordingURL: "録音ファイルのURLが設定されていません。"
        case .errorAudioSessionSetup: "オーディオセッションの設定に失敗しました。"
        case .errorAudioFileCreation: "オーディオファイルの作成に失敗しました"
        case .errorSegmentMerge: "音声セグメントの結合に失敗しました"

        // Transcription Errors
        case .errorWhisperKitInit: "WhisperKit の初期化に失敗しました"
        case .errorModelNotFound: "が見つかりません"
        case .errorModelDownload: "モデルのダウンロードに失敗しました"
        case .errorModelLoad: "モデルの読み込みに失敗しました"
        case .errorTranscription: "文字起こしに失敗しました"
        case .errorAudioLoad: "音声ファイルの読み込みに失敗しました"
        case .errorModelNotLoaded: "モデルが読み込まれていません。先にモデルをダウンロードしてください。"
        case .errorUnknown: "不明なエラー"
        }
    }
}

// swiftlint:enable file_length type_body_length
