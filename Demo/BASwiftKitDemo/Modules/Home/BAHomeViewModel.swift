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
            ),
            BADemoItem(
                title: "动画 / Animation",
                subtitle: "Spring、Shake、Pulse、Slide 等常用动画",
                iconSystemName: "wand.and.stars",
                gradient: [UIColor(ba_hex: "#FF6BCB")!, UIColor(ba_hex: "#9B5BFF")!],
                builder: { BAAnimationDemoViewController(viewModel: BAAnimationDemoViewModel()) }
            ),
            BADemoItem(
                title: "字体 / UIFont",
                subtitle: "系统字重快捷、Dynamic Type、字体注册",
                iconSystemName: "textformat.size",
                gradient: [UIColor(ba_hex: "#0EA5E9")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BAFontDemoViewController(viewModel: BAFontDemoViewModel()) }
            ),
            BADemoItem(
                title: "多语言 / BALocalization",
                subtitle: "运行时切换语言，无需重启 App",
                iconSystemName: "globe",
                gradient: [UIColor(ba_hex: "#22C55E")!, UIColor(ba_hex: "#0EA5E9")!],
                builder: { BAL10nDemoViewController(viewModel: BAL10nDemoViewModel()) }
            ),
            BADemoItem(
                title: "加载 HUD",
                subtitle: "全屏 / 局部 / 动态更新文案",
                iconSystemName: "arrow.triangle.2.circlepath",
                gradient: [UIColor(ba_hex: "#F97316")!, UIColor(ba_hex: "#F2A22C")!],
                builder: { BALoadingDemoViewController(viewModel: BALoadingDemoViewModel()) }
            ),
            BADemoItem(
                title: "自定义 NavigationBar",
                subtitle: "实心 / 渐变 / 透明，运行时切换",
                iconSystemName: "rectangle.dashed",
                gradient: [UIColor(ba_hex: "#5B6CFF")!, UIColor(ba_hex: "#1FBFB8")!],
                builder: { BANavBarDemoViewController(viewModel: BANavBarDemoViewModel()) }
            ),
            BADemoItem(
                title: "自定义 TabBar",
                subtitle: "弹跳动画 + 角标，BATabBarController",
                iconSystemName: "square.grid.3x1.below.line.grid.1x2",
                gradient: [UIColor(ba_hex: "#9B5BFF")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BATabBarDemoLauncher.make() }
            ),
            BADemoItem(
                title: "基础设施 / Bundle · Window · TopVC",
                subtitle: "组件化 bundle、当前 VC、UIView 闭包点击 / 长按",
                iconSystemName: "rectangle.connected.to.line.below",
                gradient: [UIColor(ba_hex: "#16213E")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BAInfraDemoViewController(viewModel: BAInfraDemoViewModel()) }
            )
        ])
    }
}
