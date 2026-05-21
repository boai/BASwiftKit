//
//  BAFontDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

struct BAFontDemoRow {
    let label: String
    let font: UIFont
}

final class BAFontDemoViewModel {

    let rows: BAObservable<[BAFontDemoRow]> = BAObservable([])

    func loadData() {
        rows.update([
            BAFontDemoRow(label: "ba_regular(28)",  font: .ba_regular(28)),
            BAFontDemoRow(label: "ba_medium(22)",   font: .ba_medium(22)),
            BAFontDemoRow(label: "ba_semibold(18)", font: .ba_semibold(18)),
            BAFontDemoRow(label: "ba_bold(15)",     font: .ba_bold(15)),
            BAFontDemoRow(label: "ba_mono(14, .medium)", font: .ba_mono(14, weight: .medium)),
            BAFontDemoRow(label: "ba_scaled(16, .body)（跟随系统字号）",
                          font: .ba_scaled(16, weight: .regular, textStyle: .body))
        ])
    }
}
