//
//  IconSettingsTab.swift
//  WhisperPad
//

import ComposableArchitecture
import SwiftUI

/// アイコン設定タブ
///
/// メニューバーに表示するアイコンと色を各状態ごとにカスタマイズできます。
struct IconSettingsTab: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            Section {
                iconPreviewSection
            } header: {
                Text("プレビュー")
            }

            Section {
                ForEach(IconConfigStatus.allCases) { status in
                    IconConfigurationView(
                        status: status,
                        config: binding(for: status),
                        onReset: { store.send(.resetIconSetting(status)) }
                    )
                }
            } header: {
                HStack {
                    Text("状態ごとのアイコン設定")
                    Spacer()
                    Button("デフォルトに戻す") {
                        store.send(.resetMenuBarIconSettings)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    .help("すべてのアイコン設定を初期値に戻します")
                    .accessibilityLabel("デフォルトに戻す")
                    .accessibilityHint("すべてのアイコン設定を初期値に戻します")
                }
            } footer: {
                Text("各状態でメニューバーに表示されるアイコンと色を設定できます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    /// アイコンプレビューセクション
    @ViewBuilder
    private var iconPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("設定したアイコンのプレビュー:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                ForEach(IconConfigStatus.allCases) { status in
                    VStack(spacing: 4) {
                        let config = store.settings.general.menuBarIconSettings.config(for: status)
                        Image(systemName: config.symbolName)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color(nsColor: config.color))
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                            .accessibilityLabel("\(status.rawValue)のアイコン: \(config.symbolName)")

                        Text(status.rawValue)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, 8)
        }
    }

    /// 状態に対応するアイコン設定のバインディングを作成
    /// - Parameter status: 状態タイプ
    /// - Returns: StatusIconConfig のバインディング
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

// MARK: - Preview

#Preview {
    IconSettingsTab(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
    .frame(width: 520, height: 500)
}
