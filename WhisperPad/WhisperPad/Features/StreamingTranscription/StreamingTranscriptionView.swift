//
//  StreamingTranscriptionView.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// ストリーミング文字起こしポップアップのビュー
struct StreamingTranscriptionView: View {
    @Bindable var store: StoreOf<StreamingTranscriptionFeature>

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
            "録音を中止しますか？",
            isPresented: $store.showCancelConfirmation
        ) {
            Button("続ける", role: .cancel) {
                store.send(.cancelConfirmationDismissed)
            }
            Button("中止して閉じる", role: .destructive) {
                store.send(.cancelConfirmationConfirmed)
            }
        } message: {
            Text("録音中のデータは破棄されます。")
        }
    }
}

// MARK: - HeaderView

private struct HeaderView: View {
    let store: StoreOf<StreamingTranscriptionFeature>

    var body: some View {
        HStack {
            // ステータスインジケーター
            StatusIndicator(status: store.status)

            Spacer()

            // 経過時間
            HStack(spacing: 4) {
                Text("経過時間")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(formatDuration(store.duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("経過時間 \(formatDurationAccessible(store.duration))")

            Spacer()

            // 閉じるボタン
            Button {
                store.send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("閉じる")
            .accessibilityLabel("閉じる")
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
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
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
        .accessibilityLabel("\(statusText)、\(statusColorName)インジケーター")
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
            "待機中"
        case .initializing:
            "初期化中"
        case .recording:
            "録音中"
        case .processing:
            "処理中"
        case .completed:
            "完了"
        case .error:
            "エラー"
        }
    }

    private var isPulsing: Bool {
        if case .recording = status { return true }
        return false
    }

    private var statusColorName: String {
        switch status {
        case .idle:
            "グレー"
        case .initializing:
            "黄色"
        case .recording:
            "赤"
        case .processing:
            "青"
        case .completed:
            "緑"
        case .error:
            "オレンジ"
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
                    // 確定済みテキスト
                    if !store.confirmedText.isEmpty {
                        Text(store.confirmedText)
                            .foregroundColor(.primary)
                    }

                    // 未確定テキスト
                    if !store.pendingText.isEmpty {
                        Text(store.pendingText)
                            .foregroundColor(.secondary)
                    }

                    // デコード中テキスト
                    if !store.decodingText.isEmpty {
                        Text(store.decodingText)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }

                    // カーソル（録音中のみ）
                    if store.isRecording {
                        Text("▋")
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                            .accessibilityHidden(true)
                    }

                    // スクロールアンカー
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
            return "文字起こしテキストなし"
        }
        return "文字起こし: " + parts.joined(separator: " ")
    }
}

// MARK: - FooterView

private struct FooterView: View {
    let store: StoreOf<StreamingTranscriptionFeature>

    var body: some View {
        HStack {
            // 処理速度表示
            Text(String(format: "%.1f tok/s", store.tokensPerSecond))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // ボタン群
            footerButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch store.status {
        case .idle, .initializing:
            // 待機中/初期化中はボタンなし
            EmptyView()

        case .recording:
            // 録音中: 停止ボタン
            Button {
                store.send(.stopButtonTapped)
            } label: {
                Text("停止")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityLabel("停止")
            .accessibilityHint("録音を停止します")

        case .processing:
            // 処理中: 処理中表示
            ProgressView()
                .controlSize(.small)
            Text("処理中...")
                .font(.caption)
                .foregroundColor(.secondary)

        case .completed:
            // 完了: ファイル保存とコピーボタン
            Button {
                store.send(.saveToFileButtonTapped)
            } label: {
                Text("ファイル保存")
            }
            .buttonStyle(.bordered)
            .hoverTooltip(store.popupSaveToFileShortcut)
            .accessibilityLabel("ファイル保存")
            .accessibilityHint("文字起こしをファイルに保存します")

            Button {
                store.send(.copyAndCloseButtonTapped)
            } label: {
                Text("コピーして閉じる")
            }
            .buttonStyle(.borderedProminent)
            .hoverTooltip(store.popupCopyAndCloseShortcut)
            .accessibilityLabel("コピーして閉じる")
            .accessibilityHint("文字起こしをクリップボードにコピーしてウィンドウを閉じます")

        case let .error(message):
            // エラー: エラーメッセージ表示
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
                confirmedText: "今日の会議では来期の予算について話し合いました。",
                pendingText: "主な議題は以下の通りです。",
                decodingText: "マーケティング費用の",
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
                    text: "今日の会議では来期の予算について話し合いました。主な議題は以下の通りです。"
                ),
                confirmedText:
                "今日の会議では来期の予算について話し合いました。主な議題は以下の通りです。",
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
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
            }
            .overlay(alignment: .top) {
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
                        .offset(y: -28)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeOut(duration: 0.15), value: isHovering)
                }
            }
    }
}

extension View {
    func hoverTooltip(_ text: String) -> some View {
        modifier(HoverTooltipModifier(text: text))
    }
}
