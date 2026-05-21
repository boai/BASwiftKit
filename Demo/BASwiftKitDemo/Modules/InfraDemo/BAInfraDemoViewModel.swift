//
//  BAInfraDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

struct BAInfraRow {
    let label: String
    let value: String
}

final class BAInfraDemoViewModel {

    let rows: BAObservable<[BAInfraRow]> = BAObservable([])

    func refresh() {
        let main = Bundle.main
        let topVC = UIApplication.shared.ba_topViewController
        let topClass = topVC.map { String(describing: type(of: $0)) } ?? "-"
        let keyWindow = UIApplication.shared.ba_keyWindow
        let windowDesc = keyWindow.map {
            "frame=\(Int($0.bounds.width))×\(Int($0.bounds.height)) isKey=\($0.isKeyWindow)"
        } ?? "-"

        rows.update([
            BAInfraRow(label: "Bundle App",       value: main.ba_appName),
            BAInfraRow(label: "Bundle Version",   value: "\(main.ba_appVersion) (\(main.ba_buildNumber))"),
            BAInfraRow(label: "Bundle ID",        value: main.ba_bundleId),
            BAInfraRow(label: "Top VC",           value: topClass),
            BAInfraRow(label: "Key Window",       value: windowDesc),
            BAInfraRow(label: "Component Bundle", value: BAResourceBundle
                .ba_resolve(anchorClass: BAInfraDemoViewModel.self, bundleName: "BASwiftKit")?
                .bundlePath ?? "fallback → Bundle(for: self)")
        ])
    }
}
