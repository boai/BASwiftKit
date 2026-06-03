//
//  BANavBarDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import DemoCommon

public struct BANavBarStylePreset {

    let title: String
    let style: BANavigationBarStyle
}

public final class BANavBarDemoViewModel {

    public init() {}

    let presets: BAObservable<[BANavBarStylePreset]> = BAObservable([])

    func loadData() {
        presets.update([
            BANavBarStylePreset(
                title: "默认 · 浅色实心",
                style: BANavigationBarStyle(
                    background: .solid(BAAppTheme.background),
                    tintColor: BAAppTheme.accent,
                    titleColor: BAAppTheme.textPrimary
                )
            ),
            BANavBarStylePreset(
                title: "品牌渐变",
                style: BANavigationBarStyle(
                    background: .gradient(colors: BAAppTheme.brandGradient, direction: .horizontal),
                    tintColor: .white,
                    titleColor: .white
                )
            ),
            BANavBarStylePreset(
                title: "落日渐变",
                style: BANavigationBarStyle(
                    background: .gradient(colors: [UIColor(ba_hex: "#F2A22C")!, UIColor(ba_hex: "#EF4F4F")!],
                                          direction: .leadingDiagonal),
                    tintColor: .white,
                    titleColor: .white
                )
            ),
            BANavBarStylePreset(
                title: "透明",
                style: BANavigationBarStyle(
                    background: .transparent,
                    tintColor: BAAppTheme.accent,
                    titleColor: BAAppTheme.textPrimary
                )
            )
        ])
    }
}
