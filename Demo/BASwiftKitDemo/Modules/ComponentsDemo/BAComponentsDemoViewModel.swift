//
//  BAComponentsDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAComponentsDemoViewModel {

    struct GradientSample {
        let name: String
        let colors: [UIColor]
        let direction: BAGradientView.Direction
    }

    struct BadgeSample {
        let text: String
        let color: UIColor
    }

    let gradients: BAObservable<[GradientSample]> = BAObservable([])
    let badges: BAObservable<[BadgeSample]> = BAObservable([])

    func loadData() {
        gradients.update([
            GradientSample(name: "Brand", colors: BAAppTheme.brandGradient, direction: .leadingDiagonal),
            GradientSample(name: "Sunset",
                           colors: [UIColor(ba_hex: "#F2A22C")!, UIColor(ba_hex: "#EF4F4F")!],
                           direction: .horizontal),
            GradientSample(name: "Mint",
                           colors: [UIColor(ba_hex: "#2BB673")!, UIColor(ba_hex: "#1FBFB8")!],
                           direction: .trailingDiagonal),
            GradientSample(name: "Sky",
                           colors: [UIColor(ba_hex: "#3A8DFF")!, UIColor(ba_hex: "#5B6CFF")!],
                           direction: .vertical)
        ])

        badges.update([
            BadgeSample(text: "NEW",      color: BAAppTheme.danger),
            BadgeSample(text: "BETA",     color: BAAppTheme.warning),
            BadgeSample(text: "FREE",     color: BAAppTheme.success),
            BadgeSample(text: "PRO",      color: BAAppTheme.accent),
            BadgeSample(text: "v\(BASwiftKit.version)", color: BAAppTheme.accentSecondary)
        ])
    }
}
