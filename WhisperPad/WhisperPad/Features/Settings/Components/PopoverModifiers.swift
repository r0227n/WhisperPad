//
//  PopoverModifiers.swift
//  WhisperPad
//

import SwiftUI

// MARK: - Settings Popover Modifier

extension View {
    /// 設定画面用の共通ポップオーバー修飾子
    ///
    /// 一貫したスタイル（最小幅280、パディング）でポップオーバーを表示します。
    ///
    /// - Parameters:
    ///   - isPresented: ポップオーバーの表示状態
    ///   - arrowEdge: 矢印の位置（デフォルト: .trailing）
    ///   - content: ポップオーバーの内容
    func settingsPopover(
        isPresented: Binding<Bool>,
        arrowEdge: Edge = .trailing,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        self.popover(isPresented: isPresented, arrowEdge: arrowEdge) {
            content()
                .padding()
                .frame(minWidth: 280)
        }
    }
}
