//
//  BATabBarDemoRouter.swift
//  TabBarDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 自定义 TabBar Demo 路由注册器。
///
/// 负责注册自定义 TabBar 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BATabBarDemoRouter)
final class BATabBarDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.UI.tabbar, title: "自定义 TabBar", sourceType: .push) { _ in
            BATabBarDemoLauncher.make()
        }
    }
}
