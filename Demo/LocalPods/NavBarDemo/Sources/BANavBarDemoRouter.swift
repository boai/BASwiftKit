//
//  BANavBarDemoRouter.swift
//  NavBarDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 自定义 NavigationBar Demo 路由注册器。
///
/// 负责注册自定义导航栏演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BANavBarDemoRouter)
final class BANavBarDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/ui/navbar", title: "自定义 NavigationBar", sourceType: .push) { _ in
            BANavBarDemoViewController(viewModel: BANavBarDemoViewModel())
        }
    }
}
