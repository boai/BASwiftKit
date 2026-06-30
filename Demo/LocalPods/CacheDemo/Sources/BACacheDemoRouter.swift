//
//  BACacheDemoRouter.swift
//  CacheDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// Cache 缓存 Demo 路由注册器。
///
/// 负责注册缓存演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BACacheDemoRouter)
final class BACacheDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.cache, title: "Cache 缓存框架", sourceType: .push) { _ in
            BACacheDemoViewController(viewModel: BACacheDemoViewModel())
        }
    }
}
