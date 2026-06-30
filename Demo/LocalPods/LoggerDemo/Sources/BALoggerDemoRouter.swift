//
//  BALoggerDemoRouter.swift
//  LoggerDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 日志埋点 Demo 路由注册器。
///
/// 负责注册日志埋点 / Logger 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BALoggerDemoRouter)
final class BALoggerDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/logger", title: "日志埋点 / Logger", sourceType: .push) { _ in
            BALoggerDemoViewController()
        }
    }
}
