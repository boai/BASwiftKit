//
//  BADemoRouteRegistrar.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/03.
//

import UIKit
import BASwiftKit
import DemoCommon

// ──────────────────────────────────────────────
//  Import all demo pods（每个 demo 为一个独立本地 pod）
// ──────────────────────────────────────────────
import AnimationDemo
import CacheDemo
import ColorDemo
import ComponentsDemo
import CountdownDemo
import DeviceInfoDemo
import FontDemo
import InfraDemo
import L10nDemo
import LoadingDemo
import LoggerDemo
import MediaDataDemo
import NavBarDemo
import NetworkCryptoDemo
import ParamPassingDemo
import RouterDemo
import ScannerDemo
import SocketDemo
import StorageDemo
import StringDemo
import TabBarDemo
import ToastDemo
import UtilitiesDemo
import WaterfallDemo
import WebViewDemo

/// 全局 Demo 路由注册器。
///
/// 在 AppDelegate 中调用 `BADemoRouteRegistrar.registerAll()`，
/// 将所有 Demo 页面的路由一次性注册到 `BARouter`。
///
/// **路由路径统一使用 `BADemoRoutes` 常量**，避免散落字符串。
public enum BADemoRouteRegistrar {

    // MARK: - Register All

    /// 注册全部 Demo 路由。
    public static func registerAll() {
        BARouter.shared.setup()

        // 注册 App URL Scheme
        BAURLParser.registeredSchemes.insert(BADemoRoutes.scheme)

        registerUI()
        registerFeedback()
        registerFoundation()

        print("[BADemoRouteRegistrar] 所有 Demo 路由注册完成（已注册路由: \(BARouter.shared.debugAllRoutes().count) 条）")
    }

    // MARK: - Private Helpers

    /// 创建路由配置：action 内构建 VC 并 push。
    private static func demoRoute(
        pattern: String,
        title: String,
        builder: @escaping () -> UIViewController
    ) -> BARouteConfig {
        BARouteConfig(
            pattern: pattern,
            targetType: .action({ _, completion in
                let vc = builder()
                vc.title = title
                vc.hidesBottomBarWhenPushed = true
                if let nav = UIApplication.ba_currentViewController?.navigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    UIApplication.ba_currentViewController?.present(vc, animated: true)
                }
                completion?()
            }),
            sourceType: .push,
            animated: true
        )
    }

    // MARK: - UI 类 Demo

    private static func registerUI() {
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.color, title: "颜色 / UIColor") {
            BAColorDemoViewController(viewModel: BAColorDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.components, title: "UI 组件") {
            BAComponentsDemoViewController(viewModel: BAComponentsDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.animation, title: "动画 / Animation") {
            BAAnimationDemoViewController(viewModel: BAAnimationDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.font, title: "字体 / UIFont") {
            BAFontDemoViewController(viewModel: BAFontDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.waterfall, title: "瀑布流 FlowLayout") {
            BAWaterfallDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.pagedWaterfall, title: "横向分页瀑布流") {
            BAPagedWaterfallDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.navbar, title: "自定义 NavigationBar") {
            BANavBarDemoViewController(viewModel: BANavBarDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.tabbar, title: "自定义 TabBar") {
            BATabBarDemoLauncher.make()
        })
    }

    // MARK: - Feedback 类 Demo

    private static func registerFeedback() {
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Feedback.toast, title: "全局 Toast") {
            BAToastDemoViewController(viewModel: BAToastDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Feedback.loading, title: "加载 HUD / Progress") {
            BALoadingDemoViewController(viewModel: BALoadingDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Feedback.emptyView, title: "EmptyView / 空状态") {
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Feedback.alert, title: "自定义 Alert / 表单") {
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        })
    }

    // MARK: - Foundation 类 Demo

    private static func registerFoundation() {
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.string, title: "字符串 / String") {
            BAStringDemoViewController(viewModel: BAStringDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.l10n, title: "多语言 / BALocalization") {
            BAL10nDemoViewController(viewModel: BAL10nDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.socket, title: "Socket / WebSocket") {
            BASocketDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.countdown, title: "倒计时 / Countdown") {
            BACountdownDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.logger, title: "日志埋点 / Logger") {
            BALoggerDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.routerDemo, title: "路由 / Router") {
            BARouterDemoViewController()
        })
        // 跨模块路由 Caller 页面
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.routerCaller, title: "跨模块传参 & 回调") {
            BARouterCallerViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.networkCrypto, title: "Network & Crypto") {
            BANetworkCryptoDemoViewController(viewModel: BANetworkCryptoDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.scanner, title: "扫一扫 / Scanner") {
            BAScannerDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.infra, title: "基础设施 / Codable · Network") {
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.storage, title: "Storage 存储工具") {
            BAStorageDemoViewController(viewModel: BAStorageDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.utilities, title: "工具封装") {
            BAUtilitiesDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.mediaData, title: "Data & Image") {
            BAMediaDataDemoViewController()
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.deviceInfo, title: "设备信息 + 清缓存") {
            BADeviceInfoDemoViewController(viewModel: BADeviceInfoDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.cache, title: "Cache 缓存框架") {
            BACacheDemoViewController(viewModel: BACacheDemoViewModel())
        })
        BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.webView, title: "WebView 封装") {
            BAWebViewDemoViewController()
        })
        // ──────────────────────────────────────────────
        //  参数传递 + 回调 Demo（跨模块路由）
        //
        //  路由路径: /demo/foundation/param-passing
        //  Caller:   BARouterCallerViewController（主 App）
        //  Target:   BAParamPassingDemoViewController（ParamPassingDemo pod）
        //
        //  数据流: Caller → BARouteRequest.params → Target
        //          Target → BARouter.sendCallback() → Caller 回调闭包
        // ──────────────────────────────────────────────
        BARouter.shared.register(
            BARouteConfig(
                pattern: BADemoRoutes.Foundation.paramPassing,
                targetType: .action({ params, completion in
                    // 从路由参数中提取回调令牌（由 BARouter.open(_:callback:) 自动注入）
                    let token = params["_ba_callback_token"] as? BARouteCallbackToken
                    let vc = BAParamPassingDemoViewController(routeToken: token)
                    vc.title = "参数传递 & 回调"
                    vc.hidesBottomBarWhenPushed = true

                    // 将路由参数注入到 VC（遵循 BARoutable 协议）
                    vc.receiveRouteParams(params)

                    if let nav = UIApplication.ba_currentViewController?.navigationController {
                        nav.pushViewController(vc, animated: true)
                    } else {
                        UIApplication.ba_currentViewController?.present(vc, animated: true)
                    }
                    completion?()
                }),
                sourceType: .push,
                animated: true
            )
        )
    }
}
