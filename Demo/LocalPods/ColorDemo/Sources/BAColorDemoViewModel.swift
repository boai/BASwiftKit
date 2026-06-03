//
//  BAColorDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

public struct BAColorSwatch {

    let title: String
    let color: UIColor
    let hex: String
}

public final class BAColorDemoViewModel {

    public init() {}

    let swatches: BAObservable<[BAColorSwatch]> = BAObservable([])
    let randomColor: BAObservable<UIColor> = BAObservable(.systemBlue)

    func loadData() {
        let palette: [(String, String)] = [
            ("Aurora",   "#31D7FF"),
            ("Ultraviolet", "#8F5CFF"),
            ("Lagoon",   "#20E3B2"),
            ("Royal",    "#2F80ED"),
            ("Sunset",   "#F2A53B"),
            ("Flamingo", "#F05260"),
            ("Midnight", "#111827"),
            ("Cream",    "#F6D7A7")
        ]
        swatches.update(palette.map {
            BAColorSwatch(title: $0.0,
                        color: UIColor(ba_hex: $0.1) ?? .systemBlue,
                        hex: $0.1)
        })
    }

    func roll() {
        randomColor.update(.ba_random)
    }
}
