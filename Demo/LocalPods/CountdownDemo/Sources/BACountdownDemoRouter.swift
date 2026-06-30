//
//  BACountdownDemoRouter.swift
//  CountdownDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 倒计时 Demo 路由注册器。
///
/// 负责注册倒计时演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BACountdownDemoRouter)
final class BACountdownDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.countdown, title: "倒计时 / Countdown", sourceType: .push) { _ in
            BACountdownDemoViewController()
        }
    }
}
