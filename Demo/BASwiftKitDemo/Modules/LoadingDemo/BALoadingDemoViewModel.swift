//
//  BALoadingDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

struct BALoadingScenario {
    let title: String
    let action: (UIView) -> Void
}

final class BALoadingDemoViewModel {

    let scenarios: BAObservable<[BALoadingScenario]> = BAObservable([])

    func loadData() {
        scenarios.update([
            BALoadingScenario(title: "全屏 1.5s") { _ in
                BALoadingHUD.ba_show(message: "加载中…")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    BALoadingHUD.ba_hide()
                }
            },
            BALoadingScenario(title: "嵌入当前视图 2s") { container in
                BALoadingHUD.ba_show(in: container, message: "局部加载…")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    BALoadingHUD.ba_hide(from: container)
                }
            },
            BALoadingScenario(title: "动态更新文字（步进 3 步）") { _ in
                BALoadingHUD.ba_show(message: "Step 1 / 3")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    BALoadingHUD.ba_show(message: "Step 2 / 3")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    BALoadingHUD.ba_show(message: "Step 3 / 3 ✅")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    BALoadingHUD.ba_hide()
                }
            }
        ])
    }
}
