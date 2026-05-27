//
//  BAHomeViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAHomeViewModel {

    let title: String
    let subtitle: String

    let items: BAObservable<[BADemoItem]> = BAObservable([])
    private let provider: () -> [BADemoItem]

    init(title: String = "BASwiftKit",
         subtitle: String = "MVVM · UIKit · 可独立提取的常用封装",
         provider: @escaping () -> [BADemoItem] = BADemoCatalog.allItems) {
        self.title = title
        self.subtitle = subtitle
        self.provider = provider
    }

    func loadData() {
        items.update(provider())
    }
}

enum BADemoRootFactory {

    static func make() -> UIViewController {
        let tab = BATabBarController()
        tab.ba_selectedColor = BAAppTheme.accent
        tab.ba_unselectedColor = BAAppTheme.textSecondary
        tab.title = "BASwiftKit"
        tab.ba_setup(items: [
            BATabItem(title: "UI",
                      icon: UIImage(systemName: "square.grid.2x2"),
                      selectedIcon: UIImage(systemName: "square.grid.2x2.fill"),
                      viewController: BAHomeViewController(viewModel: BAHomeViewModel(
                        title: "UI Components",
                        subtitle: "颜色、组件、动画、字体与导航层能力",
                        provider: BADemoCatalog.uiItems
                      ))),
            BATabItem(title: "Feedback",
                      icon: UIImage(systemName: "bell.badge"),
                      selectedIcon: UIImage(systemName: "bell.badge.fill"),
                      viewController: BAHomeViewController(viewModel: BAHomeViewModel(
                        title: "Feedback",
                        subtitle: "Toast、Loading、Alert、EmptyView 等全局反馈",
                        provider: BADemoCatalog.feedbackItems
                      ))),
            BATabItem(title: "Foundation",
                      icon: UIImage(systemName: "shippingbox"),
                      selectedIcon: UIImage(systemName: "shippingbox.fill"),
                      viewController: BAHomeViewController(viewModel: BAHomeViewModel(
                        title: "Foundation",
                        subtitle: "字符串、多语言、设备、Codable、网络与基础设施",
                        provider: BADemoCatalog.foundationItems
                      )))
        ])
        return tab
    }
}

enum BADemoCatalog {

    static func allItems() -> [BADemoItem] {
        uiItems() + feedbackItems() + foundationItems()
    }

    static func uiItems() -> [BADemoItem] {
        [
            BADemoItem(
                title: "颜色 / UIColor",
                subtitle: "Hex 构造、随机色、暗黑模式适配",
                iconSystemName: "paintpalette.fill",
                gradient: [UIColor(ba_hex: "#5B6CFF")!, UIColor(ba_hex: "#9B5BFF")!],
                builder: { BAColorDemoViewController(viewModel: BAColorDemoViewModel()) }
            ),
            BADemoItem(
                title: "UI 组件",
                subtitle: "卡片、渐变、Badge、EmptyView 等开箱即用控件",
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
            )
        ]
    }

    static func feedbackItems() -> [BADemoItem] {
        [
            BADemoItem(
                title: "全局 Toast",
                subtitle: "成功 / 失败 / 警告 / 默认四种风格",
                iconSystemName: "bubble.left.and.bubble.right.fill",
                gradient: [UIColor(ba_hex: "#F2A22C")!, UIColor(ba_hex: "#EF4F4F")!],
                builder: { BAToastDemoViewController(viewModel: BAToastDemoViewModel()) }
            ),
            BADemoItem(
                title: "加载 HUD / Progress",
                subtitle: "全屏 Loading + SVProgress 风格全局提示",
                iconSystemName: "arrow.triangle.2.circlepath",
                gradient: [UIColor(ba_hex: "#F97316")!, UIColor(ba_hex: "#F2A22C")!],
                builder: { BALoadingDemoViewController(viewModel: BALoadingDemoViewModel()) }
            ),
            BADemoItem(
                title: "EmptyView / 空状态",
                subtitle: "图片、标题、内容、按钮、间距自由配置",
                iconSystemName: "tray",
                gradient: [UIColor(ba_hex: "#20E3B2")!, UIColor(ba_hex: "#2F80ED")!],
                builder: { BAInfraDemoViewController(viewModel: BAInfraDemoViewModel()) }
            ),
            BADemoItem(
                title: "自定义 Alert / 表单",
                subtitle: "自定义弹窗、TextField、TextView、DatePicker",
                iconSystemName: "rectangle.on.rectangle.angled",
                gradient: [UIColor(ba_hex: "#8F5CFF")!, UIColor(ba_hex: "#4F7CFF")!],
                builder: { BAInfraDemoViewController(viewModel: BAInfraDemoViewModel()) }
            )
        ]
    }

    static func foundationItems() -> [BADemoItem] {
        [
            BADemoItem(
                title: "字符串 / String",
                subtitle: "MD5、Base64、邮箱手机号校验、文本测量",
                iconSystemName: "textformat",
                gradient: [UIColor(ba_hex: "#2BB673")!, UIColor(ba_hex: "#1FBFB8")!],
                builder: { BAStringDemoViewController(viewModel: BAStringDemoViewModel()) }
            ),
            BADemoItem(
                title: "多语言 / BALocalization",
                subtitle: "运行时切换语言，无需重启 App",
                iconSystemName: "globe",
                gradient: [UIColor(ba_hex: "#22C55E")!, UIColor(ba_hex: "#0EA5E9")!],
                builder: { BAL10nDemoViewController(viewModel: BAL10nDemoViewModel()) }
            ),
            BADemoItem(
                title: "Network & Crypto",
                subtitle: "网络请求拆分、Endpoint、SHA/HMAC/AES 加密",
                iconSystemName: "lock.shield.fill",
                gradient: [UIColor(ba_hex: "#16213E")!, UIColor(ba_hex: "#0EA5E9")!],
                builder: { BANetworkCryptoDemoViewController(viewModel: BANetworkCryptoDemoViewModel()) }
            ),
            BADemoItem(
                title: "基础设施 / Codable · Network",
                subtitle: "模型互转、网络请求、列表订阅、Bundle/TopVC",
                iconSystemName: "rectangle.connected.to.line.below",
                gradient: [UIColor(ba_hex: "#16213E")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BAInfraDemoViewController(viewModel: BAInfraDemoViewModel()) }
            ),
            BADemoItem(
                title: "Storage 存储工具",
                subtitle: "FileManager、UserDefaults、缓存大小与清理",
                iconSystemName: "folder.fill.badge.gearshape",
                gradient: [UIColor(ba_hex: "#1FBFB8")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BAStorageDemoViewController(viewModel: BAStorageDemoViewModel()) }
            ),
            BADemoItem(
                title: "工具封装",
                subtitle: "正则校验、系统跳转、权限状态封装",
                iconSystemName: "wrench.and.screwdriver.fill",
                gradient: [UIColor(ba_hex: "#8F5CFF")!, UIColor(ba_hex: "#0EA5E9")!],
                builder: { BAUtilitiesDemoViewController() }
            ),
            BADemoItem(
                title: "Data & Image",
                subtitle: "字节解析、CRC、分包、UIImage 常用处理",
                iconSystemName: "photo.on.rectangle.angled",
                gradient: [UIColor(ba_hex: "#FF6BCB")!, UIColor(ba_hex: "#F97316")!],
                builder: { BAMediaDataDemoViewController() }
            ),
            BADemoItem(
                title: "设备信息 + 清缓存",
                subtitle: "机型 / 电池 / 存储 / 一键清 Caches & tmp",
                iconSystemName: "iphone.gen3",
                gradient: [UIColor(ba_hex: "#1FBFB8")!, UIColor(ba_hex: "#5B6CFF")!],
                builder: { BADeviceInfoDemoViewController(viewModel: BADeviceInfoDemoViewModel()) }
            ),
            BADemoItem(
                title: "Cache 缓存框架",
                subtitle: "内存 / 磁盘 / 混合缓存 + 过期策略 + LRU",
                iconSystemName: "externaldrive.fill",
                gradient: [UIColor(ba_hex: "#FF6B6B")!, UIColor(ba_hex: "#F9CA24")!],
                builder: { BACacheDemoViewController(viewModel: BACacheDemoViewModel()) }
            ),
            BADemoItem(
                title: "WebView 封装",
                subtitle: "WKWebView + 拦截 + 进度条 + JS 交互",
                iconSystemName: "safari.fill",
                gradient: [UIColor(ba_hex: "#0ABDE3")!, UIColor(ba_hex: "#10AC84")!],
                builder: { BAWebViewDemoViewController() }
            )
        ]
    }
}
