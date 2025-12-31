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
            Text("経過時間")
                .foregroundColor(.secondary)
                .font(.caption)
            Text(formatDuration(store.duration))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)

            Spacer()

            // 閉じるボタン
            Button {
                store.send(.cancelButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("閉じる")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
}

// MARK: - PulseModifier

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? (isPulsing ? 0.5 : 1.0) : 1.0)
            .animation(
                isActive ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if isActive { isPulsing = true }
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}

// MARK: - TextDisplayView

private struct TextDisplayView: View {
    let store: StoreOf<StreamingTranscriptionFeature>

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
                    }

                    // スクロールアンカー
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: store.confirmedText) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: store.pendingText) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxHeight: .infinity)
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

            Button {
                store.send(.copyAndCloseButtonTapped)
            } label: {
                Text("コピーして閉じる")
            }
            .buttonStyle(.borderedProminent)

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
