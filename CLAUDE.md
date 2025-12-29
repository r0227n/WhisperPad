# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhisperPad (WhisperPad) is a macOS menu bar application for voice-to-text transcription using WhisperKit for on-device speech recognition. The app runs entirely locally without network requirements.

**Requirements**: macOS 14.0+ (Sonoma), Apple Silicon (M1/M2/M3/M4)

## Development Commands

All commands use mise. Run `mise install` first to set up tools.

```bash
# Format
mise run format          # Run all formatters (Swift + Prettier)
mise run format:swift    # Format Swift files only

# Lint
mise run lint            # Run all linters
mise run lint:swift      # SwiftLint
mise run lint:swift:strict  # SwiftLint with --strict (CI mode)

# CI Check (no file modifications)
mise run check           # lint:swift:strict + format:swift:check + lint:prettier

# Auto-fix
mise run fix             # Format + lint fix all files
```

## Architecture

Uses **The Composable Architecture (TCA)** v1.23.1+ for state management.

### Planned Module Structure

```
App/
├── AppReducer.swift          # Root reducer
├── AppDelegate.swift         # Menu bar management
Features/
├── Recording/                # Audio recording (AVFoundation)
├── Transcription/            # WhisperKit integration
├── Settings/                 # User preferences
├── History/                  # Transcription history
Clients/
├── AudioRecorderClient       # Recording dependency
├── TranscriptionClient       # WhisperKit dependency
├── HotKeyClient              # Global hotkey (soffes/HotKey)
├── OutputClient              # Clipboard/file output
```

### Key Dependencies

- **WhisperKit**: On-device speech recognition (CoreML)
- **HotKey**: Global keyboard shortcuts
- **AVFoundation**: Audio recording

## Code Style

### SwiftLint Rules (v0.62.2)

- Line length: warning at 120, error at 200
- Function body: max 50 lines (warning), 100 (error)
- No `print()` statements (use logging instead)

### SwiftFormat (v0.58.7)

- Swift 5.10, 4-space indent, 120 char line width
- K&R brace style, `--self remove`

## Specification

Detailed specification available at `docs/spec.md` (1080 lines) including:

- State machine diagrams
- UI specifications
- Error handling patterns
- Whisper model options (tiny/base/small/medium/large-v3)
