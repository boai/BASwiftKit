//
//  BAColorDemoRouter.swift
//  ColorDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 颜色 Demo 路由注册器。
///
/// 负责注册颜色演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAColorDemoRouter)
final class BAColorDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.UI.color, title: "颜色 / UIColor", sourceType: .push) { _ in
            BAColorDemoViewController(viewModel: BAColorDemoViewModel())
        }
    }
}
