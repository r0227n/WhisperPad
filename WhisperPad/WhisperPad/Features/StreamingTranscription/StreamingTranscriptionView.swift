//
//  StreamingTranscriptionView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// Streaming transcription popup view
struct StreamingTranscriptionView: View {
    @Bindable var store: StoreOf<StreamingTranscriptionFeature>
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store)

            Divider()

            TextDisplayView(store: store)

            Divider()

            FooterView(store: store)
        }
        .frame(width: 400, height: 300)
        .background(Color.clear)
        .onAppear {
            store.send(.onAppear)
        }
        .alert(
            L10n.get(.streamingStopConfirmTitle),
            isPresented: $store.showCancelConfirmation
        ) {
            Button(L10n.get(.streamingContinue), role: .cancel) {
                store.send(.cancelConfirmationDismissed)
            }
            Button(L10n.get(.streamingStopAndClose), role: .destructive) {
                store.send(.cancelConfirmationConfirmed)
            }
        } message: {
            Text(L10n.get(.streamingStopConfirmMessage))
        }
    }
}

// MARK: - HeaderView

private struct HeaderView: View {
    let store: StoreOf<StreamingTranscriptionFeature>

    var body: some View {
        HStack {
            // Status indicator
            StatusIndicator(status: store.status)

            Spacer()

            // Elapsed time
            HStack(spacing: 4) {
                Text(L10n.get(.streamingElapsedTime))
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(formatDuration(store.duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(L10n.get(.streamingElapsedTime)) \(formatDurationAccessible(store.duration))")

            Spacer()

            // Close button
            Button {
                store.send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverTooltip(store.popupCloseShortcut, alignment: .bottom)
            .accessibilityLabel(L10n.get(.streamingClose))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatDurationAccessible(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - StatusIndicator

private struct StatusIndicator: View {
    let status: StreamingStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .modifier(PulseModifier(isActive: isPulsing))

            Text(statusText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statusText), \(statusColorName)")
    }

    private var statusColor: Color {
        switch status {
        case .idle:
            .gray
        case .initializing:
            .yellow
        case .recording:
            .red
        case .processing:
            .blue
        case .completed:
            .green
        case .error:
            .orange
        }
    }

    private var statusText: String {
        switch status {
        case .idle:
            L10n.get(.streamingStatusIdle)
        case .initializing:
            L10n.get(.streamingStatusInitializing)
        case .recording:
            L10n.get(.streamingStatusRecording)
        case .processing:
            L10n.get(.streamingStatusProcessing)
        case .completed:
            L10n.get(.streamingStatusCompleted)
        case .error:
            L10n.get(.streamingStatusError)
        }
    }

    private var isPulsing: Bool {
        if case .recording = status { return true }
        return false
    }

    private var statusColorName: String {
        switch status {
        case .idle:
            L10n.get(.streamingColorGray)
        case .initializing:
            L10n.get(.streamingColorYellow)
        case .recording:
            L10n.get(.streamingColorRed)
        case .processing:
            L10n.get(.streamingColorBlue)
        case .completed:
            L10n.get(.streamingColorGreen)
        case .error:
            L10n.get(.streamingColorOrange)
        }
    }
}

// MARK: - PulseModifier

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isActive && !reduceMotion ? (isPulsing ? 0.5 : 1.0) : 1.0)
            .animation(
                isActive && !reduceMotion
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if isActive, !reduceMotion { isPulsing = true }
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue && !reduceMotion
            }
    }
}

// MARK: - TextDisplayView

private struct TextDisplayView: View {
    let store: StoreOf<StreamingTranscriptionFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // Confirmed text
                    if !store.confirmedText.isEmpty {
                        Text(store.confirmedText)
                            .foregroundColor(.primary)
                    }

                    // Pending text
                    if !store.pendingText.isEmpty {
                        Text(store.pendingText)
                            .foregroundColor(.secondary)
                    }

                    // Decoding text
                    if !store.decodingText.isEmpty {
                        Text(store.decodingText)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }

                    // Cursor (recording only)
                    if store.isRecording {
                        Text("▋")
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                            .accessibilityHidden(true)
                    }

                    // Scroll anchor
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(transcriptionAccessibilityLabel)
            }
            .onChange(of: store.confirmedText) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: store.pendingText) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo("bottom", anchor: .bottom)
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var transcriptionAccessibilityLabel: String {
        var parts: [String] = []
        if !store.confirmedText.isEmpty {
            parts.append(store.confirmedText)
        }
        if !store.pendingText.isEmpty {
            parts.append(store.pendingText)
        }
        if !store.decodingText.isEmpty {
            parts.append(store.decodingText)
        }
        if parts.isEmpty {
            return L10n.get(.streamingNoTranscription)
        }
        return L10n.get(.streamingTranscriptionPrefix) + parts.joined(separator: " ")
    }
}

// MARK: - FooterView

private struct FooterView: View {
    let store: StoreOf<StreamingTranscriptionFeature>

    var body: some View {
        HStack {
            // Processing speed display
            Text(String(format: "%.1f \(L10n.get(.streamingTokensPerSecond))", store.tokensPerSecond))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Buttons
            footerButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch store.status {
        case .idle, .initializing:
            // No buttons while idle/initializing
            EmptyView()

        case .recording:
            // Recording: Stop button
            Button {
                store.send(.stopButtonTapped)
            } label: {
                Text(L10n.get(.streamingStop))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityLabel(L10n.get(.streamingStop))
            .accessibilityHint(L10n.get(.streamingStopRecording))

        case .processing:
            // Processing: Progress display
            ProgressView()
                .controlSize(.small)
            Text(L10n.get(.streamingProcessing))
                .font(.caption)
                .foregroundColor(.secondary)

        case .completed:
            // Completed: Save to file and copy buttons
            Button {
                store.send(.saveToFileButtonTapped)
            } label: {
                Text(L10n.get(.streamingSaveToFile))
            }
            .buttonStyle(.bordered)
            .hoverTooltip(store.popupSaveToFileShortcut)
            .accessibilityLabel(L10n.get(.streamingSaveToFile))
            .accessibilityHint(L10n.get(.streamingSaveDescription))

            Button {
                store.send(.copyAndCloseButtonTapped)
            } label: {
                Text(L10n.get(.streamingCopyAndClose))
            }
            .buttonStyle(.borderedProminent)
            .hoverTooltip(store.popupCopyAndCloseShortcut)
            .accessibilityLabel(L10n.get(.streamingCopyAndClose))
            .accessibilityHint(L10n.get(.streamingCopyDescription))

        case let .error(message):
            // Error: Error message display
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    StreamingTranscriptionView(
        store: Store(initialState: StreamingTranscriptionFeature.State()) {
            StreamingTranscriptionFeature()
        }
    )
    .background(Color(nsColor: .windowBackgroundColor))
}

#Preview("Recording") {
    StreamingTranscriptionView(
        store: Store(
            initialState: StreamingTranscriptionFeature.State(
                status: .recording(duration: 15, tokensPerSecond: 12.5),
                confirmedText: "Today's meeting discussed the budget for next term.",
                pendingText: "The main topics are as follows.",
                decodingText: "Marketing costs",
                duration: 15,
                tokensPerSecond: 12.5
            )
        ) {
            StreamingTranscriptionFeature()
        }
    )
    .background(Color(nsColor: .windowBackgroundColor))
}

#Preview("Completed") {
    StreamingTranscriptionView(
        store: Store(
            initialState: StreamingTranscriptionFeature.State(
                status: .completed(
                    text: "Today's meeting discussed the budget for next term. The main topics are as follows."
                ),
                confirmedText:
                "Today's meeting discussed the budget for next term. The main topics are as follows.",
                duration: 30,
                tokensPerSecond: 0
            )
        ) {
            StreamingTranscriptionFeature()
        }
    )
    .background(Color(nsColor: .windowBackgroundColor))
}

// MARK: - HoverTooltip

private struct HoverTooltipModifier: ViewModifier {
    let text: String
    let alignment: VerticalAlignment

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .overlay(alignment: alignment == .bottom ? .bottom : .top) {
                if isHovering, !text.isEmpty {
                    Text(text)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        )
                        .offset(y: alignment == .bottom ? 28 : -28)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeOut(duration: 0.15), value: isHovering)
                        .allowsHitTesting(false)
                }
            }
    }
}

extension View {
    func hoverTooltip(_ text: String, alignment: VerticalAlignment = .top) -> some View {
        modifier(HoverTooltipModifier(text: text, alignment: alignment))
    }
}
