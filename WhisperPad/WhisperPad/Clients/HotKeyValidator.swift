//
//  HotKeyValidator.swift
//  WhisperPad
//
//  Created by Claude Code
//

import Carbon
import OSLog

private let logger = Logger(subsystem: "com.r0227n.WhisperPad", category: "HotKeyValidator")

enum HotKeyValidator {
    enum ValidationError: Error {
        case systemConflict(OSStatus)
        case invalidCombo
        case reservedSystemShortcut
    }

    private struct SystemShortcut: Hashable {
        let keyCode: UInt32
        let modifiers: UInt32
    }

    // Comprehensive system shortcut blocklist
    // Carbon modifier flag constants:
    // cmdKey = 256, shiftKey = 512, optionKey = 2048, controlKey = 4096
    private static let systemReservedShortcuts: Set<SystemShortcut> = [
        // === Clipboard & Text Operations ===
        SystemShortcut(keyCode: 8, modifiers: 256), // Cmd+C (Copy)
        SystemShortcut(keyCode: 9, modifiers: 256), // Cmd+V (Paste)
        SystemShortcut(keyCode: 7, modifiers: 256), // Cmd+X (Cut)
        SystemShortcut(keyCode: 0, modifiers: 256), // Cmd+A (Select All)
        SystemShortcut(keyCode: 6, modifiers: 256), // Cmd+Z (Undo)
        SystemShortcut(keyCode: 6, modifiers: 768), // Cmd+Shift+Z (Redo) [256+512]

        // === File Operations ===
        SystemShortcut(keyCode: 1, modifiers: 256), // Cmd+S (Save)
        SystemShortcut(keyCode: 31, modifiers: 256), // Cmd+O (Open)
        SystemShortcut(keyCode: 35, modifiers: 256), // Cmd+P (Print)
        SystemShortcut(keyCode: 45, modifiers: 256), // Cmd+N (New Window)

        // === Window & App Management ===
        SystemShortcut(keyCode: 12, modifiers: 256), // Cmd+Q (Quit)
        SystemShortcut(keyCode: 13, modifiers: 256), // Cmd+W (Close Window)
        SystemShortcut(keyCode: 17, modifiers: 256), // Cmd+T (New Tab)
        SystemShortcut(keyCode: 4, modifiers: 256), // Cmd+H (Hide App)
        SystemShortcut(keyCode: 46, modifiers: 256), // Cmd+M (Minimize)
        SystemShortcut(keyCode: 4, modifiers: 2304), // Cmd+Option+H (Hide Others) [256+2048]

        // === Search & Navigation ===
        SystemShortcut(keyCode: 3, modifiers: 256), // Cmd+F (Find)
        SystemShortcut(keyCode: 5, modifiers: 256), // Cmd+G (Find Next)
        SystemShortcut(keyCode: 5, modifiers: 768), // Cmd+Shift+G (Find Previous) [256+512]
        SystemShortcut(keyCode: 49, modifiers: 256), // Cmd+Space (Spotlight)
        SystemShortcut(keyCode: 48, modifiers: 256), // Cmd+Tab (App Switcher)
        SystemShortcut(keyCode: 48, modifiers: 768), // Cmd+Shift+Tab (Reverse App Switcher) [256+512]

        // === Preferences & Settings ===
        SystemShortcut(keyCode: 43, modifiers: 256), // Cmd+, (Preferences)

        // === Text Formatting ===
        SystemShortcut(keyCode: 11, modifiers: 256), // Cmd+B (Bold)
        SystemShortcut(keyCode: 34, modifiers: 256), // Cmd+I (Italic / Get Info)
        SystemShortcut(keyCode: 32, modifiers: 256), // Cmd+U (Underline)
        SystemShortcut(keyCode: 40, modifiers: 256), // Cmd+K (Insert Link)

        // === Finder Specific ===
        SystemShortcut(keyCode: 2, modifiers: 256), // Cmd+D (Duplicate / Bookmark)
        SystemShortcut(keyCode: 14, modifiers: 256), // Cmd+E (Eject)
        SystemShortcut(keyCode: 16, modifiers: 256), // Cmd+Y (Quick Look)
        SystemShortcut(keyCode: 51, modifiers: 256), // Cmd+Delete (Move to Trash)
        SystemShortcut(keyCode: 51, modifiers: 768), // Cmd+Shift+Delete (Empty Trash) [256+512]

        // === Screenshots ===
        SystemShortcut(keyCode: 3, modifiers: 768), // Cmd+Shift+3 (Screenshot) [256+512]
        SystemShortcut(keyCode: 4, modifiers: 768), // Cmd+Shift+4 (Selection Screenshot) [256+512]
        SystemShortcut(keyCode: 5, modifiers: 768), // Cmd+Shift+5 (Screenshot App) [256+512]

        // === Special Characters & Input ===
        SystemShortcut(keyCode: 49, modifiers: 2304), // Cmd+Option+Space (Character Viewer) [256+2048]

        // === Navigation in Lists/Text ===
        SystemShortcut(keyCode: 123, modifiers: 256), // Cmd+Left (Move to line start)
        SystemShortcut(keyCode: 124, modifiers: 256), // Cmd+Right (Move to line end)
        SystemShortcut(keyCode: 125, modifiers: 256), // Cmd+Down (Move to document end)
        SystemShortcut(keyCode: 126, modifiers: 256), // Cmd+Up (Move to document start)

        // === Browser/Safari Common ===
        SystemShortcut(keyCode: 15, modifiers: 256), // Cmd+R (Reload)
        SystemShortcut(keyCode: 37, modifiers: 256), // Cmd+L (Location/Address Bar)

        // === Mission Control & Spaces ===
        SystemShortcut(keyCode: 126, modifiers: 4096), // Control+Up (Mission Control)
        SystemShortcut(keyCode: 125, modifiers: 4096), // Control+Down (App Windows)

        // === Additional Critical Shortcuts ===
        SystemShortcut(keyCode: 36, modifiers: 256), // Cmd+Return (Open in new window)
        SystemShortcut(keyCode: 50, modifiers: 256), // Cmd+` (Switch windows in app)
        SystemShortcut(keyCode: 18, modifiers: 768), // Cmd+Shift+1 (Show Desktop) [256+512]
        SystemShortcut(keyCode: 47, modifiers: 256) // Cmd+. (Cancel operation)
    ]

    /// Check if a shortcut is reserved by macOS system
    static func isSystemReservedShortcut(
        carbonKeyCode: UInt32,
        carbonModifiers: UInt32
    ) -> Bool {
        let shortcut = SystemShortcut(
            keyCode: carbonKeyCode,
            modifiers: carbonModifiers
        )
        return systemReservedShortcuts.contains(shortcut)
    }

    /// hotkeyが登録可能かテスト（実際には登録せず、即座にアンレジスター）
    static func canRegister(
        carbonKeyCode: UInt32,
        carbonModifiers: UInt32
    ) -> Result<Void, ValidationError> {
        // Check blocklist first to prevent crashes from system-reserved shortcuts
        if isSystemReservedShortcut(
            carbonKeyCode: carbonKeyCode,
            carbonModifiers: carbonModifiers
        ) {
            logger.warning(
                "Blocked system-reserved shortcut: keyCode=\(carbonKeyCode), modifiers=\(carbonModifiers)"
            )
            return .failure(.reservedSystemShortcut)
        }

        var eventHotKey: EventHotKeyRef?
        guard let testSignature = FourCharCode("TEST") else {
            logger.error("Failed to create test FourCharCode signature")
            return .failure(.invalidCombo)
        }
        let testID = EventHotKeyID(
            signature: testSignature,
            id: UInt32.random(in: 1 ... 1_000_000)
        )

        let status = RegisterEventHotKey(
            carbonKeyCode,
            carbonModifiers,
            testID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKey
        )

        if status == noErr, let hotKeyRef = eventHotKey {
            // テスト成功 → 即座にアンレジスター
            UnregisterEventHotKey(hotKeyRef)
            logger.debug("HotKey validation succeeded: keyCode=\(carbonKeyCode), modifiers=\(carbonModifiers)")
            return .success(())
        } else {
            logger.warning(
                "HotKey validation failed: keyCode=\(carbonKeyCode), modifiers=\(carbonModifiers), status=\(status)"
            )
            return .failure(.systemConflict(status))
        }
    }

    /// アプリ内で重複しているホットキーをチェック
    /// - Parameters:
    ///   - carbonKeyCode: チェック対象のキーコード
    ///   - carbonModifiers: チェック対象の修飾キー
    ///   - currentType: 現在設定しようとしているホットキータイプ
    ///   - settings: 現在のホットキー設定
    /// - Returns: 重複している場合は重複先のHotkeyType、なければnil
    static func findDuplicate(
        carbonKeyCode: UInt32,
        carbonModifiers: UInt32,
        currentType: HotkeyType,
        in settings: HotKeySettings
    ) -> HotkeyType? {
        let allHotkeys: [(HotkeyType, HotKeySettings.KeyComboSettings)] = [
            (.recording, settings.recordingHotKey),
            (.streaming, settings.streamingHotKey),
            (.cancel, settings.cancelHotKey),
            (.recordingPause, settings.recordingPauseHotKey),
            (.popupCopyAndClose, settings.popupCopyAndCloseHotKey),
            (.popupSaveToFile, settings.popupSaveToFileHotKey),
            (.popupClose, settings.popupCloseHotKey)
        ]

        // 自分自身以外で同じキーコンボを使っているものを探す
        for (type, combo) in allHotkeys where type != currentType {
            if combo.carbonKeyCode == carbonKeyCode,
               combo.carbonModifiers == carbonModifiers {
                return type
            }
        }

        return nil
    }
}
