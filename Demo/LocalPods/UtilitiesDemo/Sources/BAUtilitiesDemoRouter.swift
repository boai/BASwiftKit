//
//  BAUtilitiesDemoRouter.swift
//  UtilitiesDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 工具封装 Demo 路由注册器。
///
/// 负责注册工具封装演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAUtilitiesDemoRouter)
final class BAUtilitiesDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/utilities", title: "工具封装", sourceType: .push) { _ in
            BAUtilitiesDemoViewController()
        }
    }
}
