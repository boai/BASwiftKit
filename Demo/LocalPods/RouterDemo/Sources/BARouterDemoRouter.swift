//
//  BARouterDemoRouter.swift
//  RouterDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 路由 Demo 路由注册器。
///
/// 负责注册路由演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BARouterDemoRouter)
final class BARouterDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/router", title: "路由 / Router", sourceType: .push) { _ in
            BARouterDemoViewController()
        }
    }
}
