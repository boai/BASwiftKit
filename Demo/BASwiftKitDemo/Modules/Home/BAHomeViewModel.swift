//
//  BAHomeViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAHomeViewModel {

    let title = "BASwiftKit"
    let subtitle = "MVVM · UIKit · 可独立提取的常用封装"

    let items: BAObservable<[BADemoItem]> = BAObservable([])

    func loadData() {
        items.update([
            BADemoItem(
                title: "颜色 / UIColor",
                subtitle: "Hex 构造、随机色、暗黑模式适配",
                iconSystemName: "paintpalette.fill",
                gradient: [UIColor(ba_hex: "#5B6CFF")!, UIColor(ba_hex: "#9B5BFF")!],
                builder: { BAColorDemoViewController(viewModel: BAColorDemoViewModel()) }
            ),
            BADemoItem(
                title: "字符串 / String",
                subtitle: "MD5、Base64、邮箱手机号校验、文本测量",
                iconSystemName: "textformat",
                gradient: [UIColor(ba_hex: "#2BB673")!, UIColor(ba_hex: "#1FBFB8")!],
                builder: { BAStringDemoViewController(viewModel: BAStringDemoViewModel()) }
            ),
            BADemoItem(
                title: "全局 Toast",
                subtitle: "成功 / 失败 / 警告 / 默认四种风格",
                iconSystemName: "bubble.left.and.bubble.right.fill",
                gradient: [UIColor(ba_hex: "#F2A22C")!, UIColor(ba_hex: "#EF4F4F")!],
                builder: { BAToastDemoViewController(viewModel: BAToastDemoViewModel()) }
            ),
            BADemoItem(
                title: "UI 组件",
                subtitle: "卡片、渐变、Badge 等开箱即用控件",
                iconSystemName: "square.stack.3d.up.fill",
                gradient: [UIColor(ba_hex: "#3A8DFF")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BAComponentsDemoViewController(viewModel: BAComponentsDemoViewModel()) }
            )
        ])
    }
}
