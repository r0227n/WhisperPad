# WhisperPad

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3%2FM4-orange.svg)](https://support.apple.com/en-us/HT211814)
[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)

[日本語](./docs/README.ja.md)

A voice transcription application that resides in the macOS menu bar. Runs completely locally with on-device speech recognition powered by WhisperKit.

<p align="center">
  <img src="./docs/assets/AppIcon.iconset/icon_512x512.png" alt="icon" />
</p>

## Overview

WhisperPad starts voice recording with a global hotkey, transcribes speech to text using WhisperKit's on-device recognition, and outputs the result to the clipboard or a file.

**Privacy-focused**: All processing is done locally without requiring a network connection. Your voice data is never sent externally.

## Key Features

| Feature                 | Description                                                 |
| ----------------------- | ----------------------------------------------------------- |
| Menu Bar Resident       | Auto-launches at system startup and resides in the menu bar |
| Hotkey Recording        | Start/stop recording instantly with global shortcuts        |
| On-device Transcription | Completely local processing with WhisperKit                 |
| Flexible Output         | Output to clipboard, file, or both                          |
| Model Switching         | Switch Whisper models directly from the menu bar            |

## System Requirements

| Item      | Requirement                 |
| --------- | --------------------------- |
| OS        | macOS 14.0+ (Sonoma)        |
| Processor | Apple Silicon (M1/M2/M3/M4) |
| Memory    | 8GB or more recommended     |

### Required Permissions

- **Microphone Access**: For voice recording
- **Accessibility**: For global hotkeys

## Installation

### Build

```bash
# Clone the repository
git clone https://github.com/your-username/WhisperPad.git
cd WhisperPad

# Build
swift build -c release
```

### Development Environment Setup

```bash
# Install mise (if not already installed)
brew install mise

# Setup development tools
mise install
```

## Usage

### Basic Operation

1. Launch the app and a microphone icon will appear in the menu bar
2. Press the hotkey (default: `⌘⌥R`) to start recording
3. Press the hotkey again to stop recording and begin transcription
4. Once complete, the result is copied to the clipboard

### Hotkeys

| Shortcut | Action                        |
| -------- | ----------------------------- |
| `⌘⌥R`    | Start/Stop recording (toggle) |
| `⌘⌥P`    | Pause/Resume                  |
| `⌘⌥.`    | Cancel recording              |

### Recording Mode

- **Toggle**: Press hotkey once to start, press again to stop

### Menu Bar Icon States

| State        | Icon                       | Color  |
| ------------ | -------------------------- | ------ |
| Idle         | Microphone                 | Gray   |
| Recording    | Microphone (with waveform) | Red    |
| Paused       | Pause                      | Orange |
| Transcribing | Gear (spinning)            | Blue   |
| Complete     | Checkmark                  | Green  |
| Error        | Warning                    | Yellow |

## Settings

Customize the following items from the Settings screen (`⌘,`):

| Tab       | Contents                                                |
| --------- | ------------------------------------------------------- |
| General   | Startup settings, notifications, language, idle timeout |
| Icon      | Icon and color customization for each state             |
| Hotkey    | Hotkeys for recording, pause, and cancel                |
| Recording | Input device, audio monitoring, output settings         |
| Model     | Model search/filter, download/delete                    |

## Development

### Development Commands

```bash
# Format
mise run format          # Run all formatters
mise run format:swift    # Swift files only

# Lint
mise run lint            # Run all linters
mise run lint:swift      # SwiftLint

# CI Check (no file changes)
mise run check

# Auto-fix
mise run fix             # Format + lint fix
```

### Architecture

Uses **The Composable Architecture (TCA)** v1.23.1+ for state management.

```
WhisperPad/
├── App/            # AppReducer, AppDelegate
├── Features/       # TCA Feature modules
│   ├── Recording/      # Audio recording
│   ├── Transcription/  # Transcription
│   └── Settings/       # Settings
├── Clients/        # External service integrations
│   ├── AudioRecorderClient   # Recording & microphone permissions
│   ├── TranscriptionClient   # WhisperKit integration
│   ├── HotKeyClient          # Global hotkeys
│   └── OutputClient          # Clipboard & file output
└── Models/         # Data models
```

### Code Style

- **SwiftLint** (v0.62.2): 120 character line length, 50 lines max function body
- **SwiftFormat** (v0.58.7): Swift 5.10, 4-space indent

## Dependencies

| Library                                                             | Version | Purpose            |
| ------------------------------------------------------------------- | ------- | ------------------ |
| [WhisperKit](https://github.com/argmaxinc/WhisperKit)               | 0.15.0+ | Speech recognition |
| [TCA](https://github.com/pointfreeco/swift-composable-architecture) | 1.23.1+ | State management   |
| [HotKey](https://github.com/soffes/HotKey)                          | 0.2.1+  | Global hotkeys     |
