//
//  BAColorDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

struct BAColorSwatch {
    let title: String
    let color: UIColor
    let hex: String
}

final class BAColorDemoViewModel {

    let swatches: BAObservable<[BAColorSwatch]> = BAObservable([])
    let randomColor: BAObservable<UIColor> = BAObservable(.systemBlue)

    func loadData() {
        let palette: [(String, String)] = [
            ("Indigo",   "#5B6CFF"),
            ("Violet",   "#9B5BFF"),
            ("Mint",     "#2BB673"),
            ("Cyan",     "#1FBFB8"),
            ("Sunset",   "#F2A22C"),
            ("Coral",    "#EF4F4F"),
            ("Navy",     "#16213E"),
            ("Sand",     "#F6D7A7")
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
