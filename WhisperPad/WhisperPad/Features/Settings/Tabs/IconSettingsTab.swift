//
//  IconSettingsTab.swift
//  WhisperPad
//

import AppKit
import ComposableArchitecture
import SwiftUI

/// Icon settings tab
///
/// Configures menu bar icons in master-detail format.
/// Left panel: Status-based icon list
/// Right panel: Details and editing of selected status
struct IconSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    /// Selected status
    @State private var selectedStatus: IconConfigStatus = .idle

    var body: some View {
        HSplitView {
            // Left panel: Icon status list
            iconListPanel
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)

            // Right panel: Details
            detailPanel
                .frame(minWidth: 300)
        }
    }

    // MARK: - Left Panel

    /// Icon list panel
    private var iconListPanel: some View {
        List(selection: $selectedStatus) {
            Section {
                ForEach(IconConfigStatus.allCases) { status in
                    IconListRow(
                        status: status,
                        config: store.settings.general.menuBarIconSettings.config(for: status)
                    )
                    .tag(status)
                }
            } header: {
                Text(L10n.get(.iconStatus))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Right Panel

    /// Detail panel
    private var detailPanel: some View {
        IconDetailPanel(
            status: selectedStatus,
            config: binding(for: selectedStatus),
            onReset: { store.send(.resetIconSetting(selectedStatus)) }
        )
    }

    // MARK: - Helpers

    /// Create binding for icon configuration corresponding to status
    /// - Parameter status: Status type
    /// - Returns: Binding of StatusIconConfig
    private func binding(for status: IconConfigStatus) -> Binding<StatusIconConfig> {
        Binding(
            get: {
                store.settings.general.menuBarIconSettings.config(for: status)
            },
            set: { newConfig in
                var settings = store.settings.general.menuBarIconSettings
                settings.setConfig(newConfig, for: status)
                var general = store.settings.general
                general.menuBarIconSettings = settings
                store.send(.updateGeneralSettings(general))
            }
        )
    }
}

// MARK: - IconListRow

/// Icon list row
private struct IconListRow: View {
    let status: IconConfigStatus
    let config: StatusIconConfig

    var body: some View {
        HStack(spacing: 12) {
            // Icon preview
            Image(systemName: config.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(nsColor: config.color))
                .font(.system(size: 18))
                .frame(width: 24, height: 24)

            // Status name
            Text(status.displayName)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityLabel("\(status.displayName) \(L10n.get(.iconSection))")
    }
}

// MARK: - IconDetailPanel

/// Icon detail panel
private struct IconDetailPanel: View {
    let status: IconConfigStatus
    @Binding var config: StatusIconConfig
    let onReset: () -> Void

    /// Managed as SwiftUI Color (for synchronization with NSColor)
    @State private var selectedColor: Color

    /// Preset colors
    private let presetColors: [NSColor] = [
        .systemGray,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemBlue,
        .systemGreen,
        .systemPurple
    ]

    init(
        status: IconConfigStatus,
        config: Binding<StatusIconConfig>,
        onReset: @escaping () -> Void
    ) {
        self.status = status
        self._config = config
        self.onReset = onReset
        self._selectedColor = State(initialValue: Color(nsColor: config.wrappedValue.color))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header: Icon and title
                headerSection

                Divider()

                // Description section
                descriptionSection

                // Icon edit section
                iconEditSection

                // Color edit section
                colorEditSection

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: selectedColor) { _, newColor in
            config.color = NSColor(newColor)
        }
        .onChange(of: config.color) { _, newColor in
            let newSwiftUIColor = Color(nsColor: newColor)
            if selectedColor != newSwiftUIColor {
                selectedColor = newSwiftUIColor
            }
        }
        .onChange(of: status) { _, _ in
            selectedColor = Color(nsColor: config.color)
        }
    }

    // MARK: - Sections

    /// Header section
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: config.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(nsColor: config.color))
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(Color(nsColor: config.color).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(L10n.get(.iconMenuBarIcon))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .help(L10n.get(.iconResetState))
        }
    }

    /// Description section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.get(.iconDescription), systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(status.detailedDescription)
                .foregroundColor(.primary)
        }
    }

    /// Icon edit section
    private var iconEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.get(.iconSection), systemImage: "star")
                .font(.headline)
                .foregroundColor(.secondary)

            InlineSymbolPicker(selection: $config.symbolName)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    /// Color edit section
    private var colorEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.get(.iconColor), systemImage: "paintpalette")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                // ColorPicker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 44, height: 24)

                Divider()
                    .frame(height: 24)

                // Preset color buttons
                ForEach(presetColors, id: \.self) { presetColor in
                    presetColorButton(for: presetColor)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    /// Preset color button
    @ViewBuilder
    private func presetColorButton(for presetColor: NSColor) -> some View {
        let isSelected = config.color.isApproximatelyEqual(to: presetColor)

        Button {
            config.color = presetColor
            selectedColor = Color(nsColor: presetColor)
        } label: {
            Circle()
                .fill(Color(nsColor: presetColor))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    isSelected
                        ? Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        : nil
                )
        }
        .buttonStyle(.plain)
        .help(presetColor.accessibilityName)
        .accessibilityLabel(presetColor.accessibilityName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - NSColor Extension

private extension NSColor {
    /// Determine if two colors are approximately equal
    func isApproximatelyEqual(to other: NSColor, tolerance: CGFloat = 0.01) -> Bool {
        guard let selfRGB = self.usingColorSpace(.sRGB),
              let otherRGB = other.usingColorSpace(.sRGB)
        else {
            return false
        }

        return abs(selfRGB.redComponent - otherRGB.redComponent) < tolerance
            && abs(selfRGB.greenComponent - otherRGB.greenComponent) < tolerance
            && abs(selfRGB.blueComponent - otherRGB.blueComponent) < tolerance
    }
}

// MARK: - Preview

#Preview {
    IconSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 500)
}
