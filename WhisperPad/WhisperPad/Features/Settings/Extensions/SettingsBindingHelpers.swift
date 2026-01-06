//
//  SettingsBindingHelpers.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

// MARK: - Settings Binding Helpers

extension StoreOf<SettingsFeature> {
    /// General Settings 用のバインディングを作成
    func bindingForGeneral<T: Equatable>(
        keyPath: WritableKeyPath<GeneralSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.settings.general[keyPath: keyPath] },
            set: { newValue in
                var general = self.settings.general
                general[keyPath: keyPath] = newValue
                self.send(.updateGeneralSettings(general))
            }
        )
    }

    /// Recording Settings 用のバインディングを作成
    func bindingForRecording<T: Equatable>(
        keyPath: WritableKeyPath<RecordingSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.settings.recording[keyPath: keyPath] },
            set: { newValue in
                var recording = self.settings.recording
                recording[keyPath: keyPath] = newValue
                self.send(.updateRecordingSettings(recording))
            }
        )
    }

    /// Output Settings 用のバインディングを作成
    func bindingForOutput<T: Equatable>(
        keyPath: WritableKeyPath<FileOutputSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.settings.output[keyPath: keyPath] },
            set: { newValue in
                var output = self.settings.output
                output[keyPath: keyPath] = newValue
                self.send(.updateOutputSettings(output))
            }
        )
    }

    /// Transcription Settings 用のバインディングを作成
    func bindingForTranscription<T: Equatable>(
        keyPath: WritableKeyPath<TranscriptionSettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.settings.transcription[keyPath: keyPath] },
            set: { newValue in
                var transcription = self.settings.transcription
                transcription[keyPath: keyPath] = newValue
                self.send(.updateTranscriptionSettings(transcription))
            }
        )
    }

    /// HotKey Settings 用のバインディングを作成
    func bindingForHotKey<T: Equatable>(
        keyPath: WritableKeyPath<HotKeySettings, T>
    ) -> Binding<T> {
        Binding(
            get: { self.settings.hotKey[keyPath: keyPath] },
            set: { newValue in
                var hotKey = self.settings.hotKey
                hotKey[keyPath: keyPath] = newValue
                self.send(.updateHotKeySettings(hotKey))
            }
        )
    }
}
