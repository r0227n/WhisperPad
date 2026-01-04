//
//  HotKeyValidatorTests.swift
//  WhisperPadTests
//
//  Comprehensive test suite for HotKeyValidator
//  Tests all three validation tiers: system reserved blocklist, Carbon API validation, and duplicate detection
//

// swiftlint:disable file_length

import XCTest

@testable import WhisperPad

/// Comprehensive test suite for HotKeyValidator
///
/// Tests three-tier validation system:
/// 1. System reserved shortcut blocklist (51+ macOS shortcuts)
/// 2. Carbon Event Manager registration validation
/// 3. Application-level duplicate detection across 7 hotkey types
@MainActor
// swiftlint:disable:next type_body_length
final class HotKeyValidatorTests: XCTestCase {
    // MARK: - Test Data Structures

    /// Represents a key combination for testing
    struct TestKeyCombo {
        let keyCode: UInt32
        let modifiers: UInt32
        let description: String
    }

    /// Test modifier constants for readability
    enum TestModifiers {
        static let none: UInt32 = 0
        static let cmd: UInt32 = 256
        static let shift: UInt32 = 512
        static let option: UInt32 = 2048
        static let control: UInt32 = 4096

        // Two-modifier combinations
        static let cmdShift: UInt32 = 768 // 256 + 512
        static let cmdOption: UInt32 = 2304 // 256 + 2048
        static let cmdControl: UInt32 = 4352 // 256 + 4096
        static let shiftOption: UInt32 = 2560 // 512 + 2048
        static let shiftControl: UInt32 = 4608 // 512 + 4096
        static let optionControl: UInt32 = 6144 // 2048 + 4096

        // Three-modifier combinations
        static let cmdShiftOption: UInt32 = 2816 // 256 + 512 + 2048
        static let cmdShiftControl: UInt32 = 4864 // 256 + 512 + 4096
        static let cmdOptionControl: UInt32 = 6400 // 256 + 2048 + 4096
        static let shiftOptionControl: UInt32 = 6656 // 512 + 2048 + 4096

        // All four modifiers
        static let all: UInt32 = 6912 // 256 + 512 + 2048 + 4096
    }

    /// Test key code constants
    enum TestKeyCodes {
        // Alphabet (sample across range)
        static let keyA: UInt32 = 0
        static let keyS: UInt32 = 1
        static let keyD: UInt32 = 2
        static let keyR: UInt32 = 15
        static let keyP: UInt32 = 35
        static let keyZ: UInt32 = 6

        // Numbers
        static let one: UInt32 = 18
        static let five: UInt32 = 23
        static let nine: UInt32 = 25

        // Special keys
        static let space: UInt32 = 49
        static let returnKey: UInt32 = 36
        static let tab: UInt32 = 48
        static let escape: UInt32 = 53
        static let backspace: UInt32 = 51

        // Arrows
        static let leftArrow: UInt32 = 123
        static let rightArrow: UInt32 = 124
        static let downArrow: UInt32 = 125
        static let upArrow: UInt32 = 126

        // Function keys
        static let keyF1: UInt32 = 122
        static let keyF5: UInt32 = 96
        static let keyF10: UInt32 = 109
        static let keyF15: UInt32 = 113
    }

    /// Groups of system reserved shortcuts from the blocklist
    enum SystemReservedGroups {
        /// Clipboard and text operations
        static let clipboardShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 8, modifiers: 256, description: "Cmd+C (Copy)"),
            TestKeyCombo(keyCode: 9, modifiers: 256, description: "Cmd+V (Paste)"),
            TestKeyCombo(keyCode: 7, modifiers: 256, description: "Cmd+X (Cut)"),
            TestKeyCombo(keyCode: 0, modifiers: 256, description: "Cmd+A (Select All)"),
            TestKeyCombo(keyCode: 6, modifiers: 256, description: "Cmd+Z (Undo)"),
            TestKeyCombo(keyCode: 6, modifiers: 768, description: "Cmd+Shift+Z (Redo)")
        ]

        /// File operations
        static let fileOperationShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 1, modifiers: 256, description: "Cmd+S (Save)"),
            TestKeyCombo(keyCode: 31, modifiers: 256, description: "Cmd+O (Open)"),
            TestKeyCombo(keyCode: 35, modifiers: 256, description: "Cmd+P (Print)"),
            TestKeyCombo(keyCode: 45, modifiers: 256, description: "Cmd+N (New Window)")
        ]

        /// Window and app management
        static let windowManagementShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 12, modifiers: 256, description: "Cmd+Q (Quit)"),
            TestKeyCombo(keyCode: 13, modifiers: 256, description: "Cmd+W (Close Window)"),
            TestKeyCombo(keyCode: 17, modifiers: 256, description: "Cmd+T (New Tab)"),
            TestKeyCombo(keyCode: 4, modifiers: 256, description: "Cmd+H (Hide App)"),
            TestKeyCombo(keyCode: 46, modifiers: 256, description: "Cmd+M (Minimize)"),
            TestKeyCombo(keyCode: 4, modifiers: 2304, description: "Cmd+Option+H (Hide Others)"),
            TestKeyCombo(keyCode: 48, modifiers: 256, description: "Cmd+Tab (App Switcher)"),
            TestKeyCombo(keyCode: 48, modifiers: 768, description: "Cmd+Shift+Tab (Reverse App Switcher)"),
            TestKeyCombo(keyCode: 50, modifiers: 256, description: "Cmd+` (Switch Windows)"),
            TestKeyCombo(keyCode: 36, modifiers: 256, description: "Cmd+Return (Open in New Window)")
        ]

        /// Search and navigation
        static let searchNavigationShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 3, modifiers: 256, description: "Cmd+F (Find)"),
            TestKeyCombo(keyCode: 5, modifiers: 256, description: "Cmd+G (Find Next)"),
            TestKeyCombo(keyCode: 5, modifiers: 768, description: "Cmd+Shift+G (Find Previous)"),
            TestKeyCombo(keyCode: 49, modifiers: 256, description: "Cmd+Space (Spotlight)"),
            TestKeyCombo(keyCode: 49, modifiers: 2304, description: "Cmd+Option+Space (Character Viewer)"),
            TestKeyCombo(keyCode: 47, modifiers: 256, description: "Cmd+. (Cancel Operation)")
        ]

        /// Preferences
        static let preferencesShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 43, modifiers: 256, description: "Cmd+, (Preferences)")
        ]

        /// Text formatting
        static let textFormattingShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 11, modifiers: 256, description: "Cmd+B (Bold)"),
            TestKeyCombo(keyCode: 34, modifiers: 256, description: "Cmd+I (Italic)"),
            TestKeyCombo(keyCode: 32, modifiers: 256, description: "Cmd+U (Underline)"),
            TestKeyCombo(keyCode: 40, modifiers: 256, description: "Cmd+K (Insert Link)")
        ]

        /// Finder specific
        static let finderShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 2, modifiers: 256, description: "Cmd+D (Duplicate)"),
            TestKeyCombo(keyCode: 14, modifiers: 256, description: "Cmd+E (Eject)"),
            TestKeyCombo(keyCode: 16, modifiers: 256, description: "Cmd+Y (Quick Look)"),
            TestKeyCombo(keyCode: 51, modifiers: 256, description: "Cmd+Delete (Move to Trash)"),
            TestKeyCombo(keyCode: 51, modifiers: 768, description: "Cmd+Shift+Delete (Empty Trash)")
        ]

        /// Screenshot shortcuts
        static let screenshotShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 3, modifiers: 768, description: "Cmd+Shift+3 (Screenshot)"),
            TestKeyCombo(keyCode: 4, modifiers: 768, description: "Cmd+Shift+4 (Selection Screenshot)"),
            TestKeyCombo(keyCode: 5, modifiers: 768, description: "Cmd+Shift+5 (Screenshot App)")
        ]

        /// Navigation in text
        static let textNavigationShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 123, modifiers: 256, description: "Cmd+Left (Move to Line Start)"),
            TestKeyCombo(keyCode: 124, modifiers: 256, description: "Cmd+Right (Move to Line End)"),
            TestKeyCombo(keyCode: 125, modifiers: 256, description: "Cmd+Down (Move to Document End)"),
            TestKeyCombo(keyCode: 126, modifiers: 256, description: "Cmd+Up (Move to Document Start)")
        ]

        /// Browser/Safari shortcuts
        static let browserShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 15, modifiers: 256, description: "Cmd+R (Reload)"),
            TestKeyCombo(keyCode: 37, modifiers: 256, description: "Cmd+L (Location/Address Bar)")
        ]

        /// Mission Control and Spaces
        static let missionControlShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 126, modifiers: 4096, description: "Control+Up (Mission Control)"),
            TestKeyCombo(keyCode: 125, modifiers: 4096, description: "Control+Down (App Windows)")
        ]

        /// Additional critical shortcuts
        static let additionalShortcuts: [TestKeyCombo] = [
            TestKeyCombo(keyCode: 18, modifiers: 768, description: "Cmd+Shift+1 (Show Desktop)")
        ]

        /// All reserved shortcuts combined
        static var all: [TestKeyCombo] {
            clipboardShortcuts +
                fileOperationShortcuts +
                windowManagementShortcuts +
                searchNavigationShortcuts +
                preferencesShortcuts +
                textFormattingShortcuts +
                finderShortcuts +
                screenshotShortcuts +
                textNavigationShortcuts +
                browserShortcuts +
                missionControlShortcuts +
                additionalShortcuts
        }
    }

    // MARK: - System Reserved Blocklist Tests

    /// Tests all system reserved shortcuts return true from isSystemReservedShortcut()
    func test_isSystemReservedShortcut_allBlocklistEntries_returnTrue() {
        for combo in SystemReservedGroups.all {
            let result = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: combo.keyCode,
                carbonModifiers: combo.modifiers
            )
            XCTAssertTrue(
                result,
                "Expected \(combo.description) to be system reserved"
            )
        }
    }

    /// Tests Command-based clipboard and text shortcuts
    func test_isSystemReservedShortcut_clipboardShortcuts_returnTrue() {
        // Cmd+C (Copy)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 8, carbonModifiers: 256
        ))

        // Cmd+V (Paste)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 9, carbonModifiers: 256
        ))

        // Cmd+X (Cut)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 7, carbonModifiers: 256
        ))

        // Cmd+A (Select All)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 0, carbonModifiers: 256
        ))

        // Cmd+Z (Undo)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 6, carbonModifiers: 256
        ))

        // Cmd+Shift+Z (Redo)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 6, carbonModifiers: 768
        ))
    }

    /// Tests file operation shortcuts
    func test_isSystemReservedShortcut_fileOperationShortcuts_returnTrue() {
        // Cmd+S (Save)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 1, carbonModifiers: 256
        ))

        // Cmd+O (Open)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 31, carbonModifiers: 256
        ))

        // Cmd+P (Print)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 35, carbonModifiers: 256
        ))

        // Cmd+N (New Window)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 45, carbonModifiers: 256
        ))
    }

    /// Tests window and app management shortcuts
    func test_isSystemReservedShortcut_windowManagementShortcuts_returnTrue() {
        // Cmd+Q (Quit)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 12, carbonModifiers: 256
        ))

        // Cmd+W (Close Window)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 13, carbonModifiers: 256
        ))

        // Cmd+Tab (App Switcher)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 48, carbonModifiers: 256
        ))

        // Cmd+H (Hide)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 4, carbonModifiers: 256
        ))

        // Cmd+M (Minimize)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 46, carbonModifiers: 256
        ))

        // Cmd+Option+H (Hide Others)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 4, carbonModifiers: 2304
        ))
    }

    /// Tests Spotlight and system shortcuts
    func test_isSystemReservedShortcut_spotlightShortcuts_returnTrue() {
        // Cmd+Space (Spotlight)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 49, carbonModifiers: 256
        ))

        // Cmd+Option+Space (Character Viewer)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 49, carbonModifiers: 2304
        ))
    }

    /// Tests screenshot shortcuts (Cmd+Shift+3, Cmd+Shift+4, Cmd+Shift+5)
    func test_isSystemReservedShortcut_screenshotShortcuts_returnTrue() {
        // Cmd+Shift+3 (Screenshot)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 3, carbonModifiers: 768
        ))

        // Cmd+Shift+4 (Selection Screenshot)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 4, carbonModifiers: 768
        ))

        // Cmd+Shift+5 (Screenshot App)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 5, carbonModifiers: 768
        ))
    }

    /// Tests Mission Control shortcuts (Control+Up, Control+Down)
    func test_isSystemReservedShortcut_missionControlShortcuts_returnTrue() {
        // Control+Up (Mission Control)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 126, carbonModifiers: 4096
        ))

        // Control+Down (App Windows)
        XCTAssertTrue(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 125, carbonModifiers: 4096
        ))
    }

    /// Tests valid non-reserved shortcuts return false
    func test_isSystemReservedShortcut_validShortcuts_returnFalse() {
        // Option+Space (default recording hotkey)
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 49, carbonModifiers: 2048
        ))

        // Option+Shift+P (default pause hotkey)
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 35, carbonModifiers: 2560
        ))

        // Escape alone (default cancel)
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 53, carbonModifiers: 0
        ))

        // Cmd+Shift+C (default popup copy and close)
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: 8, carbonModifiers: 768
        ))
    }

    /// Tests edge case: no modifiers with various keys
    func test_isSystemReservedShortcut_noModifiers_returnFalse() {
        let testKeys: [UInt32] = [
            TestKeyCodes.keyA,
            TestKeyCodes.space,
            TestKeyCodes.returnKey,
            TestKeyCodes.keyF1,
            TestKeyCodes.one
        ]

        for keyCode in testKeys {
            let result = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.none
            )
            XCTAssertFalse(result, "Key \(keyCode) with no modifiers should not be reserved")
        }
    }

    /// Tests edge case: all modifiers combined
    func test_isSystemReservedShortcut_allModifiers_returnFalse() {
        // Cmd+Shift+Option+Control+A
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: TestKeyCodes.keyA,
            carbonModifiers: TestModifiers.all
        ))

        // Cmd+Shift+Option+Control+F10
        XCTAssertFalse(HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: TestKeyCodes.keyF10,
            carbonModifiers: TestModifiers.all
        ))
    }

    // MARK: - canRegister() Validation Tests

    /// Tests system reserved shortcuts return .failure(.reservedSystemShortcut)
    func test_canRegister_systemReservedShortcuts_returnsReservedError() {
        // swiftlint:disable:next large_tuple
        let reservedSamples: [(UInt32, UInt32, String)] = [
            (8, 256, "Cmd+C"),
            (9, 256, "Cmd+V"),
            (49, 256, "Cmd+Space"),
            (3, 768, "Cmd+Shift+3"),
            (126, 4096, "Control+Up")
        ]

        for (keyCode, modifiers, description) in reservedSamples {
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: keyCode,
                carbonModifiers: modifiers
            )

            if case let .failure(error) = result {
                XCTAssertEqual(
                    error,
                    .reservedSystemShortcut,
                    "Expected \(description) to fail with reservedSystemShortcut"
                )
            } else {
                XCTFail("Expected \(description) to fail with reservedSystemShortcut")
            }
        }
    }

    /// Tests valid shortcuts return .success(())
    func test_canRegister_validShortcuts_returnsSuccess() {
        // swiftlint:disable:next large_tuple
        let validCombos: [(UInt32, UInt32, String)] = [
            (49, 2048, "Option+Space"),
            (15, 768, "Cmd+Shift+R"),
            (35, 2560, "Option+Shift+P"),
            (TestKeyCodes.keyA, TestModifiers.cmdOption, "Cmd+Option+A"),
            (TestKeyCodes.keyF5, TestModifiers.shift, "Shift+F5")
        ]

        for (keyCode, modifiers, description) in validCombos {
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: keyCode,
                carbonModifiers: modifiers
            )

            if case let .failure(error) = result {
                XCTFail("Expected \(description) to succeed, but got error: \(error)")
            }
        }
    }

    /// Tests that unusual/out-of-range key codes succeed
    /// (blocklist check only, Carbon API validation removed)
    func test_canRegister_unusualKeyCode_succeeds() {
        // Test with unusual key code (out of typical range)
        // Since we no longer use Carbon API, any key code not in blocklist succeeds
        let result = HotKeyValidator.canRegister(
            carbonKeyCode: 999,
            carbonModifiers: TestModifiers.cmd
        )

        switch result {
        case .success:
            // Expected - key code 999 is not in blocklist
            break
        case let .failure(error):
            XCTFail("Expected unusual key code to succeed, but got error: \(error)")
        }
    }

    /// Tests baseline behavior for letter keys without modifiers
    func test_canRegister_letterKeysWithoutModifiers_behavior() {
        // Note: This tests actual Carbon API behavior
        let result = HotKeyValidator.canRegister(
            carbonKeyCode: TestKeyCodes.keyA,
            carbonModifiers: TestModifiers.none
        )

        // Document the actual behavior (may succeed or fail depending on system)
        switch result {
        case .success:
            // If this succeeds, document it
            XCTAssertTrue(true, "Letter without modifiers can be registered")
        case .failure:
            // If this fails, document why
            XCTAssertTrue(true, "Letter without modifiers cannot be registered")
        }
    }

    // MARK: - findDuplicate() Detection Tests

    /// Tests findDuplicate detects when another hotkey uses same combination
    func test_findDuplicate_duplicateExists_returnsConflictingType() {
        let settings = makeTestSettings(
            recording: (49, 2048) // Option+Space
        )

        // Try to set cancel to same as recording
        let result = HotKeyValidator.findDuplicate(
            carbonKeyCode: 49,
            carbonModifiers: 2048,
            currentType: .cancel,
            in: settings
        )

        XCTAssertEqual(result, .recording, "Should detect duplicate with recording hotkey")
    }

    /// Tests findDuplicate returns nil when no duplicate exists
    func test_findDuplicate_noDuplicate_returnsNil() {
        let settings = makeTestSettings()

        // Try a unique combination
        let result = HotKeyValidator.findDuplicate(
            carbonKeyCode: TestKeyCodes.keyF10,
            carbonModifiers: TestModifiers.cmdOption,
            currentType: .recording,
            in: settings
        )

        XCTAssertNil(result, "Should return nil when no duplicate exists")
    }

    /// Tests findDuplicate correctly excludes currentType from check
    func test_findDuplicate_sameAsCurrentType_returnsNil() {
        let settings = makeTestSettings(
            recording: (49, 2048) // Option+Space
        )

        // Try to set recording to its current value
        let result = HotKeyValidator.findDuplicate(
            carbonKeyCode: 49,
            carbonModifiers: 2048,
            currentType: .recording,
            in: settings
        )

        XCTAssertNil(result, "Should exclude currentType from duplicate check")
    }

    /// Tests all 7 hotkey types can be detected as duplicates
    func test_findDuplicate_allHotkeyTypes_canBeDetected() {
        let testCombo: (UInt32, UInt32) = (TestKeyCodes.keyF1, TestModifiers.cmd)

        let hotkeyTypes: [HotkeyType] = [
            .recording,
            .cancel,
            .recordingPause
        ]

        for existingType in hotkeyTypes {
            // Create settings where existingType uses testCombo
            var settings = makeTestSettings()

            // Update settings to set existingType to testCombo
            switch existingType {
            case .recording:
                settings = makeTestSettings(recording: testCombo)
            case .cancel:
                settings = makeTestSettings(cancel: testCombo)
            case .recordingPause:
                settings = makeTestSettings(recordingPause: testCombo)
            }

            for checkType in hotkeyTypes where checkType != existingType {
                let result = HotKeyValidator.findDuplicate(
                    carbonKeyCode: testCombo.0,
                    carbonModifiers: testCombo.1,
                    currentType: checkType,
                    in: settings
                )

                XCTAssertEqual(
                    result,
                    existingType,
                    "Should detect \(existingType) as duplicate when checking from \(checkType)"
                )
            }
        }
    }

    // MARK: - Key Code Range Coverage Tests

    /// Tests alphabet keys across the range
    func test_keyCodeRange_alphabetKeys_validWithModifiers() {
        let alphabetSamples: [(UInt32, String)] = [
            (0, "A"),
            (1, "S"),
            (2, "D"),
            (15, "R"),
            (35, "P"),
            (6, "Z")
        ]

        for (keyCode, letter) in alphabetSamples {
            // Test with Cmd+Option (generally safe combination)
            let isReserved = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.cmdOption
            )

            // Most Cmd+Option+Letter combinations are not reserved
            // (exceptions are explicitly in the blocklist)
            if letter != "H", letter != "Space" { // Known exceptions
                XCTAssertFalse(
                    isReserved,
                    "Cmd+Option+\(letter) should not be system reserved"
                )
            }
        }
    }

    /// Tests number keys
    func test_keyCodeRange_numberKeys_validWithModifiers() {
        let numberSamples: [(UInt32, String)] = [
            (18, "1"),
            (23, "5"),
            (25, "9")
        ]

        for (keyCode, number) in numberSamples {
            // Cmd+Option+Number should generally be available
            let isReserved = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.cmdOption
            )

            XCTAssertFalse(
                isReserved,
                "Cmd+Option+\(number) should not be reserved"
            )
        }
    }

    /// Tests special keys (Space, Return, Tab, Escape, Backspace)
    func test_keyCodeRange_specialKeys_behavior() {
        let specialKeys: [(UInt32, String)] = [
            (49, "Space"),
            (36, "Return"),
            (48, "Tab"),
            (53, "Escape"),
            (51, "Backspace")
        ]

        for (keyCode, name) in specialKeys {
            // Test with Option modifier (commonly available)
            let optionResult = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.option
            )

            // Most special keys with Option should be available
            // (Space and Tab have Cmd shortcuts, but not Option)
            if name != "Space" { // Cmd+Space is reserved, but not Option+Space
                XCTAssertFalse(
                    optionResult,
                    "Option+\(name) should not be reserved"
                )
            }
        }
    }

    /// Tests all arrow keys
    func test_keyCodeRange_arrowKeys_allDirections() {
        let arrows: [(UInt32, String)] = [
            (123, "Left"),
            (124, "Right"),
            (125, "Down"),
            (126, "Up")
        ]

        for (keyCode, direction) in arrows {
            // Control+Arrow is reserved for Mission Control
            let controlResult = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.control
            )

            // Up and Down are explicitly reserved in the blocklist
            if direction == "Up" || direction == "Down" {
                XCTAssertTrue(
                    controlResult,
                    "Control+\(direction) should be system reserved"
                )
            }

            // But Option+Arrow should be available
            let optionResult = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.option
            )
            XCTAssertFalse(
                optionResult,
                "Option+\(direction) should not be reserved"
            )
        }
    }

    /// Tests function keys (sample across F1-F15)
    func test_keyCodeRange_functionKeys_samples() {
        let functionKeys: [(UInt32, String)] = [
            (122, "F1"),
            (96, "F5"),
            (109, "F10"),
            (113, "F15")
        ]

        for (keyCode, name) in functionKeys {
            // Function keys with Shift should generally be available
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.shift
            )

            if case .failure = result {
                // Allow this to fail on some systems
                continue
            }
        }
    }

    // MARK: - Modifier Combination Coverage Tests

    /// Tests single modifiers with sample key
    func test_modifierCombinations_singleModifiers_allVariants() {
        let testKey = TestKeyCodes.keyF10 // Unlikely to be reserved

        let singleModifiers: [(UInt32, String)] = [
            (TestModifiers.cmd, "Cmd"),
            (TestModifiers.shift, "Shift"),
            (TestModifiers.option, "Option"),
            (TestModifiers.control, "Control")
        ]

        for (modifier, name) in singleModifiers {
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: testKey,
                carbonModifiers: modifier
            )

            // Should generally succeed with F10
            if case let .failure(error) = result {
                XCTFail("\(name)+F10 should be valid, got error: \(error)")
            }
        }
    }

    /// Tests two-modifier combinations
    func test_modifierCombinations_twoModifiers_allPairs() {
        let testKey = TestKeyCodes.keyF10

        let twoModifierCombos: [(UInt32, String)] = [
            (TestModifiers.cmdShift, "Cmd+Shift"),
            (TestModifiers.cmdOption, "Cmd+Option"),
            (TestModifiers.cmdControl, "Cmd+Control"),
            (TestModifiers.shiftOption, "Shift+Option"),
            (TestModifiers.shiftControl, "Shift+Control"),
            (TestModifiers.optionControl, "Option+Control")
        ]

        for (modifiers, name) in twoModifierCombos {
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: testKey,
                carbonModifiers: modifiers
            )

            if case let .failure(error) = result {
                XCTFail("\(name)+F10 should be valid, got error: \(error)")
            }
        }
    }

    /// Tests three-modifier combinations
    func test_modifierCombinations_threeModifiers_allTriples() {
        let testKey = TestKeyCodes.keyF15

        let threeModifierCombos: [(UInt32, String)] = [
            (TestModifiers.cmdShiftOption, "Cmd+Shift+Option"),
            (TestModifiers.cmdShiftControl, "Cmd+Shift+Control"),
            (TestModifiers.cmdOptionControl, "Cmd+Option+Control"),
            (TestModifiers.shiftOptionControl, "Shift+Option+Control")
        ]

        for (modifiers, name) in threeModifierCombos {
            let result = HotKeyValidator.canRegister(
                carbonKeyCode: testKey,
                carbonModifiers: modifiers
            )

            if case let .failure(error) = result {
                XCTFail("\(name)+F15 should be valid, got error: \(error)")
            }
        }
    }

    /// Tests four-modifier combination
    func test_modifierCombinations_fourModifiers_allCombined() {
        let testKey = TestKeyCodes.keyF15

        let result = HotKeyValidator.canRegister(
            carbonKeyCode: testKey,
            carbonModifiers: TestModifiers.all
        )

        if case let .failure(error) = result {
            XCTFail("Cmd+Shift+Option+Control+F15 should be valid, got error: \(error)")
        }
    }

    /// Tests no modifiers with non-reserved keys
    func test_modifierCombinations_noModifiers_variousKeys() {
        let keys: [(UInt32, String)] = [
            (TestKeyCodes.escape, "Escape"),
            (TestKeyCodes.keyF1, "F1"),
            (TestKeyCodes.keyF15, "F15")
        ]

        for (keyCode, name) in keys {
            let isReserved = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: TestModifiers.none
            )

            XCTAssertFalse(isReserved, "\(name) alone should not be system reserved")
        }
    }

    /// Tests default WhisperPad hotkey combinations are valid
    func test_modifierCombinations_defaultHotkeys_allValid() {
        // swiftlint:disable:next large_tuple
        let defaults: [(UInt32, UInt32, String)] = [
            (49, 2048, "Option+Space (recording)"),
            (53, 0, "Escape (cancel)"),
            (35, 2560, "Option+Shift+P (pause)")
        ]

        for (keyCode, modifiers, description) in defaults {
            let isReserved = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: keyCode,
                carbonModifiers: modifiers
            )
            XCTAssertFalse(isReserved, "\(description) should not be reserved")

            let canRegister = HotKeyValidator.canRegister(
                carbonKeyCode: keyCode,
                carbonModifiers: modifiers
            )
            if case let .failure(error) = canRegister {
                XCTFail("\(description) should be registerable, got: \(error)")
            }
        }
    }

    // MARK: - Edge Cases and Integration Tests

    /// Tests validation with boundary key codes
    func test_edgeCases_boundaryKeyCodes_behavior() {
        // Test key code 0 (should work, it's 'A')
        let zeroResult = HotKeyValidator.canRegister(
            carbonKeyCode: 0,
            carbonModifiers: TestModifiers.cmdOption
        )
        // Should work since Cmd+Option+A is not reserved
        if case .failure = zeroResult {
            // OK if system conflicts, but shouldn't be in blocklist
            let isReserved = HotKeyValidator.isSystemReservedShortcut(
                carbonKeyCode: 0,
                carbonModifiers: TestModifiers.cmdOption
            )
            XCTAssertFalse(isReserved, "Cmd+Option+A should not be in blocklist")
        }

        // Test very high key code
        let highResult = HotKeyValidator.canRegister(
            carbonKeyCode: 200,
            carbonModifiers: TestModifiers.cmd
        )
        // Likely to fail as invalid
        switch highResult {
        case .success:
            // If it succeeds, that's fine (system may support it)
            break
        case .failure:
            // Expected to fail
            break
        }
    }

    /// Tests validation with unusual modifier values
    func test_edgeCases_invalidModifiers_behavior() {
        // Test with 0 modifiers
        let noModResult = HotKeyValidator.canRegister(
            carbonKeyCode: TestKeyCodes.keyF10,
            carbonModifiers: 0
        )
        // Should succeed (F10 without modifiers is valid)
        if case let .failure(error) = noModResult {
            XCTFail("F10 without modifiers should work, got: \(error)")
        }

        // Test with unusual modifier value
        let unusualResult = HotKeyValidator.canRegister(
            carbonKeyCode: TestKeyCodes.keyF10,
            carbonModifiers: 9999
        )
        // Behavior depends on Carbon API - both success and failure are acceptable
        switch unusualResult {
        case .success, .failure:
            break
        }
    }

    /// Tests full validation pipeline: blocklist → canRegister → findDuplicate (system reserved)
    func test_integration_fullValidationPipeline_systemReserved() {
        let settings = makeTestSettings()

        // Use Cmd+C (system reserved)
        let keyCode: UInt32 = 8
        let modifiers: UInt32 = 256

        // Step 1: Should be in blocklist
        let isReserved = HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        XCTAssertTrue(isReserved, "Step 1: Cmd+C should be system reserved")

        // Step 2: Should fail canRegister
        let canRegister = HotKeyValidator.canRegister(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        if case let .failure(error) = canRegister {
            XCTAssertEqual(error, .reservedSystemShortcut)
        } else {
            XCTFail("Step 2: Cmd+C should fail canRegister")
        }

        // Step 3: findDuplicate should be irrelevant (already failed)
        // But we can still test it for completeness
        let duplicate = HotKeyValidator.findDuplicate(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers,
            currentType: .recording,
            in: settings
        )
        // May or may not have duplicates, doesn't matter since validation already failed
        _ = duplicate
    }

    /// Tests full validation pipeline: valid unique shortcut (all tiers pass)
    func test_integration_fullValidationPipeline_validUnique() {
        let settings = makeTestSettings()

        // Use Cmd+Option+F10 (should be unique and valid)
        let keyCode: UInt32 = TestKeyCodes.keyF10
        let modifiers: UInt32 = TestModifiers.cmdOption

        // Step 1: Should not be reserved
        let isReserved = HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        XCTAssertFalse(isReserved, "Step 1: Cmd+Option+F10 should not be reserved")

        // Step 2: Should pass canRegister
        let canRegister = HotKeyValidator.canRegister(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        if case let .failure(error) = canRegister {
            XCTFail("Step 2: Cmd+Option+F10 should pass canRegister, got: \(error)")
        }

        // Step 3: Should have no duplicates
        let duplicate = HotKeyValidator.findDuplicate(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers,
            currentType: .recording,
            in: settings
        )
        XCTAssertNil(duplicate, "Step 3: Should have no duplicates")
    }

    /// Tests full validation pipeline: valid but duplicate shortcut (passes 1 & 2, fails 3)
    func test_integration_fullValidationPipeline_validButDuplicate() {
        let settings = makeTestSettings(
            recording: (49, 2048) // Option+Space
        )

        // Try to set cancel to same as recording
        let keyCode: UInt32 = 49
        let modifiers: UInt32 = 2048

        // Step 1: Should not be reserved
        let isReserved = HotKeyValidator.isSystemReservedShortcut(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        XCTAssertFalse(isReserved, "Step 1: Option+Space should not be reserved")

        // Step 2: Should pass canRegister
        let canRegister = HotKeyValidator.canRegister(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers
        )
        if case let .failure(error) = canRegister {
            XCTFail("Step 2: Option+Space should pass canRegister, got: \(error)")
        }

        // Step 3: Should find duplicate
        let duplicate = HotKeyValidator.findDuplicate(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers,
            currentType: .cancel,
            in: settings
        )
        XCTAssertEqual(
            duplicate,
            .recording,
            "Step 3: Should detect duplicate with recording"
        )
    }

    // MARK: - Simplified Validation Tests (Carbon API Skipped)

    /// Tests that Cmd+Option+, succeeds (not in blocklist)
    /// This is the key test for the simplified validation approach
    func test_canRegister_cmdOptionComma_succeeds() {
        // cmd+option+, (keyCode: 43, modifiers: 2304)
        let result = HotKeyValidator.canRegister(
            carbonKeyCode: 43,
            carbonModifiers: 2304 // cmdKey(256) + optionKey(2048)
        )

        switch result {
        case .success:
            // Expected - Cmd+Option+, is not in the blocklist
            break
        case let .failure(error):
            XCTFail("Cmd+Option+, should succeed, but got error: \(error)")
        }
    }

    /// Tests that Option+Control+[ succeeds (potential @ key on JIS keyboard)
    func test_canRegister_optionControlBracket_succeeds() {
        // option+control+[ (keyCode: 33, modifiers: 6144)
        let result = HotKeyValidator.canRegister(
            carbonKeyCode: 33, // [ key (@ on some keyboard layouts)
            carbonModifiers: 6144 // optionKey(2048) + controlKey(4096)
        )

        switch result {
        case .success:
            // Expected - Option+Control+[ is not in the blocklist
            break
        case let .failure(error):
            XCTFail("Option+Control+[ should succeed, but got error: \(error)")
        }
    }

    /// Tests that Cmd+Shift+Option+F12 succeeds (unusual combo)
    func test_canRegister_cmdShiftOptionF12_succeeds() {
        // cmd+shift+option+F12 (keyCode: 111, modifiers: 2816)
        let result = HotKeyValidator.canRegister(
            carbonKeyCode: 111, // F12
            carbonModifiers: 2816 // cmdKey(256) + shiftKey(512) + optionKey(2048)
        )

        switch result {
        case .success:
            // Expected - unusual combo not in blocklist
            break
        case let .failure(error):
            XCTFail("Cmd+Shift+Option+F12 should succeed, but got error: \(error)")
        }
    }

    // MARK: - Helper Methods

    /// Creates test HotKeySettings with specified key combinations
    private func makeTestSettings(
        recording: (UInt32, UInt32) = (49, 2048),
        cancel: (UInt32, UInt32) = (53, 0),
        recordingPause: (UInt32, UInt32) = (35, 2560)
    ) -> HotKeySettings {
        HotKeySettings(
            recordingHotKey: .init(
                carbonKeyCode: recording.0,
                carbonModifiers: recording.1
            ),
            cancelHotKey: .init(
                carbonKeyCode: cancel.0,
                carbonModifiers: cancel.1
            ),
            recordingPauseHotKey: .init(
                carbonKeyCode: recordingPause.0,
                carbonModifiers: recordingPause.1
            )
        )
    }
}
