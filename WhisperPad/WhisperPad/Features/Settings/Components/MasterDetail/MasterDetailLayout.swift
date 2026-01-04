//
//  MasterDetailLayout.swift
//  WhisperPad
//

import SwiftUI

/// マスター・ディテールレイアウト用の汎用コンテナ
///
/// 左パネル（プライマリ）と右パネル（ディテール）を持つHSplitViewレイアウトを提供します。
/// IconSettingsTabとHotkeySettingsTabで共通利用されます。
// swiftlint:disable:next inclusive_language
struct MasterDetailLayout<Primary: View, Detail: View>: View {
    /// 左パネルの最小幅
    let primaryMinWidth: CGFloat
    /// 左パネルの理想幅
    let primaryIdealWidth: CGFloat
    /// 左パネルの最大幅
    let primaryMaxWidth: CGFloat
    /// 右パネルの最小幅
    let detailMinWidth: CGFloat

    /// 左パネル（プライマリ）のコンテンツ
    @ViewBuilder let primary: () -> Primary
    /// 右パネル（ディテール）のコンテンツ
    @ViewBuilder let detail: () -> Detail

    init(
        primaryMinWidth: CGFloat = 180,
        primaryIdealWidth: CGFloat = 200,
        primaryMaxWidth: CGFloat = 240,
        detailMinWidth: CGFloat = 280,
        @ViewBuilder primary: @escaping () -> Primary,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.primaryMinWidth = primaryMinWidth
        self.primaryIdealWidth = primaryIdealWidth
        self.primaryMaxWidth = primaryMaxWidth
        self.detailMinWidth = detailMinWidth
        self.primary = primary
        self.detail = detail
    }

    var body: some View {
        HSplitView {
            primary()
                .frame(
                    minWidth: primaryMinWidth,
                    idealWidth: primaryIdealWidth,
                    maxWidth: primaryMaxWidth
                )

            detail()
                .frame(minWidth: detailMinWidth)
        }
    }
}

#Preview("Icon Settings Layout") {
    MasterDetailLayout(
        detailMinWidth: 300,
        primary: {
            List {
                Section("States") {
                    Text("Idle")
                    Text("Recording")
                    Text("Transcribing")
                }
            }
            .listStyle(.sidebar)
        },
        detail: {
            VStack(spacing: 16) {
                Text("Detail Panel")
                    .font(.title2)
                Text("Select an item from the list")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        }
    )
    .frame(width: 600, height: 400)
}

#Preview("Hotkey Settings Layout") {
    MasterDetailLayout(
        primary: {
            List {
                Section("Recording") {
                    Text("Start Recording")
                    Text("Pause Recording")
                }
                Section("Cancel") {
                    Text("Cancel")
                }
            }
            .listStyle(.sidebar)
        },
        detail: {
            VStack(spacing: 16) {
                Text("Shortcut Detail")
                    .font(.title2)
                Text("Select a shortcut from the list")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        }
    )
    .frame(width: 600, height: 400)
}
