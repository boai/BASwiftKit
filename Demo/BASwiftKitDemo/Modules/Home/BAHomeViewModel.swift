//
//  BAHomeViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import DemoCommon
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

// MARK: - Root Factory

enum BADemoRootFactory {

    /// 构造根 TabBar：三个 Tab 分别展示 UI / Feedback / Foundation 类 Demo 列表。
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

// MARK: - Demo Catalog（路由驱动）

/// 所有 Demo 以路由路径串联。
///
/// 每个 `BADemoItem` 持有一条 BARouter 路由路径，
/// 点击卡片时通过 `BARouter.shared.open(route)` 跳转。
/// 各 demo pod 的 VC 通过 `BADemoRouteRegistrar` 注册到路由表。
enum BADemoCatalog {

    static func allItems() -> [BADemoItem] {
        uiItems() + feedbackItems() + foundationItems()
    }

    // MARK: - UI

    static func uiItems() -> [BADemoItem] {
        [
            BADemoItem(title: "颜色 / UIColor",
                       subtitle: "Hex 构造、随机色、暗黑模式适配",
                       iconSystemName: "paintpalette.fill",
                       gradient: gradient("#5B6CFF", "#9B5BFF"),
                       route: "/demo/color"),
            BADemoItem(title: "UI 组件",
                       subtitle: "卡片、渐变、Badge、EmptyView 等开箱即用控件",
                       iconSystemName: "square.stack.3d.up.fill",
                       gradient: gradient("#3A8DFF", "#5B6CFF"),
                       route: "/demo/components"),
            BADemoItem(title: "动画 / Animation",
                       subtitle: "Spring、Shake、Pulse、Slide 等常用动画",
                       iconSystemName: "wand.and.stars",
                       gradient: gradient("#FF6BCB", "#9B5BFF"),
                       route: "/demo/animation"),
            BADemoItem(title: "字体 / UIFont",
                       subtitle: "系统字重快捷、Dynamic Type、字体注册",
                       iconSystemName: "textformat.size",
                       gradient: gradient("#0EA5E9", "#5B6CFF"),
                       route: "/demo/font"),
            BADemoItem(title: "瀑布流 FlowLayout",
                       subtitle: "自适应纵向/横向瀑布流、按比例动态排布",
                       iconSystemName: "rectangle.grid.2x2.fill",
                       gradient: gradient("#0EA5E9", "#22C55E"),
                       route: "/demo/waterfall"),
            BADemoItem(title: "横向分页瀑布流",
                       subtitle: "每页两行四列：第一行 1-4，第二行 5-8，自定义页码指示器",
                       iconSystemName: "rectangle.grid.2x2",
                       gradient: gradient("#111827", "#5B6CFF"),
                       route: "/demo/paged-waterfall"),
            BADemoItem(title: "自定义 NavigationBar",
                       subtitle: "实心 / 渐变 / 透明，运行时切换",
                       iconSystemName: "rectangle.dashed",
                       gradient: gradient("#5B6CFF", "#1FBFB8"),
                       route: "/demo/navbar"),
            BADemoItem(title: "自定义 TabBar",
                       subtitle: "弹跳动画 + 角标，BATabBarController",
                       iconSystemName: "square.grid.3x1.below.line.grid.1x2",
                       gradient: gradient("#9B5BFF", "#5B6CFF"),
                       route: "/demo/tabbar")
        ]
    }

    // MARK: - Feedback

    static func feedbackItems() -> [BADemoItem] {
        [
            BADemoItem(title: "全局 Toast",
                       subtitle: "成功 / 失败 / 警告 / 默认四种风格",
                       iconSystemName: "bubble.left.and.bubble.right.fill",
                       gradient: gradient("#F2A22C", "#EF4F4F"),
                       route: "/demo/toast"),
            BADemoItem(title: "加载 HUD / Progress",
                       subtitle: "全屏 Loading + SVProgress 风格全局提示",
                       iconSystemName: "arrow.triangle.2.circlepath",
                       gradient: gradient("#F97316", "#F2A22C"),
                       route: "/demo/loading"),
            BADemoItem(title: "EmptyView / 空状态",
                       subtitle: "图片、标题、内容、按钮、间距自由配置",
                       iconSystemName: "tray",
                       gradient: gradient("#20E3B2", "#2F80ED"),
                       route: "/demo/emptyview"),
            BADemoItem(title: "自定义 Alert / 表单",
                       subtitle: "自定义弹窗、TextField、TextView、DatePicker",
                       iconSystemName: "rectangle.on.rectangle.angled",
                       gradient: gradient("#8F5CFF", "#4F7CFF"),
                       route: "/demo/alert")
        ]
    }

    // MARK: - Foundation

    static func foundationItems() -> [BADemoItem] {
        [
            BADemoItem(title: "字符串 / String",
                       subtitle: "MD5、Base64、邮箱手机号校验、文本测量",
                       iconSystemName: "textformat",
                       gradient: gradient("#2BB673", "#1FBFB8"),
                       route: "/demo/string"),
            BADemoItem(title: "多语言 / BALocalization",
                       subtitle: "运行时切换语言，无需重启 App",
                       iconSystemName: "globe",
                       gradient: gradient("#22C55E", "#0EA5E9"),
                       route: "/demo/l10n"),
            BADemoItem(title: "Socket / WebSocket",
                       subtitle: "基于 Starscream 的 Socket 封装，支持多类型解析与自动重连",
                       iconSystemName: "antenna.radiowaves.left.and.right",
                       gradient: BAAppTheme.brandGradient,
                       route: "/demo/socket"),
            BADemoItem(title: "倒计时 / Countdown",
                       subtitle: "列表共享 Timer、截止时间精准同步、刷新不丢秒",
                       iconSystemName: "timer",
                       gradient: gradient("#FF4D4F", "#FF7A45"),
                       route: "/demo/countdown"),
            BADemoItem(title: "日志埋点 / Logger",
                       subtitle: "自动埋点、SQLite 持久化、按日加密导出 TXT",
                       iconSystemName: "doc.text.magnifyingglass",
                       gradient: gradient("#111827", "#3B82F6"),
                       route: "/demo/logger"),
            BADemoItem(title: "路由 / Router",
                       subtitle: "TheRouter 范式封装：URL 跳转 + 服务发现 + 拦截器链",
                       iconSystemName: "arrow.triangle.branch",
                       gradient: gradient("#3B82F6", "#8B5CF6"),
                       route: "/demo/router"),
            BADemoItem(title: "Network & Crypto",
                       subtitle: "网络请求拆分、Endpoint、SHA/HMAC/AES 加密",
                       iconSystemName: "lock.shield.fill",
                       gradient: gradient("#16213E", "#0EA5E9"),
                       route: "/demo/network-crypto"),
            BADemoItem(title: "扫一扫 / Scanner",
                       subtitle: "独立相机扫码、二维码/条码识别、手电筒控制",
                       iconSystemName: "qrcode.viewfinder",
                       gradient: gradient("#111827", "#22C55E"),
                       route: "/demo/scanner"),
            BADemoItem(title: "基础设施 / Codable · Network",
                       subtitle: "模型互转、网络请求、列表订阅、Bundle/TopVC",
                       iconSystemName: "rectangle.connected.to.line.below",
                       gradient: gradient("#16213E", "#5B6CFF"),
                       route: "/demo/infra"),
            BADemoItem(title: "Storage 存储工具",
                       subtitle: "FileManager、UserDefaults、缓存大小与清理",
                       iconSystemName: "folder.fill.badge.gearshape",
                       gradient: gradient("#1FBFB8", "#5B6CFF"),
                       route: "/demo/storage"),
            BADemoItem(title: "工具封装",
                       subtitle: "正则校验、系统跳转、权限状态封装",
                       iconSystemName: "wrench.and.screwdriver.fill",
                       gradient: gradient("#8F5CFF", "#0EA5E9"),
                       route: "/demo/utilities"),
            BADemoItem(title: "Data & Image",
                       subtitle: "字节解析、CRC、分包、UIImage 常用处理",
                       iconSystemName: "photo.on.rectangle.angled",
                       gradient: gradient("#FF6BCB", "#F97316"),
                       route: "/demo/media-data"),
            BADemoItem(title: "设备信息 + 清缓存",
                       subtitle: "机型 / 电池 / 存储 / 一键清 Caches & tmp",
                       iconSystemName: "iphone.gen3",
                       gradient: gradient("#1FBFB8", "#5B6CFF"),
                       route: "/demo/device-info"),
            BADemoItem(title: "Cache 缓存框架",
                       subtitle: "内存 / 磁盘 / 混合缓存 + 过期策略 + LRU",
                       iconSystemName: "externaldrive.fill",
                       gradient: gradient("#FF6B6B", "#F9CA24"),
                       route: "/demo/cache"),
            BADemoItem(title: "WebView 封装",
                       subtitle: "WKWebView + 拦截 + 进度条 + JS 交互",
                       iconSystemName: "safari.fill",
                       gradient: gradient("#0ABDE3", "#10AC84"),
                       route: "/demo/webview")
        ]
    }

    // MARK: - Private Helpers

    private static func gradient(_ hex1: String, _ hex2: String) -> [UIColor] {
        [UIColor(ba_hex: hex1)!, UIColor(ba_hex: hex2)!]
    }
}
