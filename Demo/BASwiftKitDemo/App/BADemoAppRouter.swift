//
//  BADemoAppRouter.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/04.
//

import UIKit
import BASwiftKit
import DemoCommon

/// 主 Demo App 路由注册器。
///
/// 注册主 App 中不属于任何独立 Pod 的页面路由
/// （如跨模块路由 Caller 页面等）。
@objc(BADemoAppRouter)
final class BADemoAppRouter: NSObject, BARouteModule {

    // MARK: - Register All

    static func registerRoutes() {
        registerRouterCaller()
    }

    // MARK: - Route Pages

    /// 跨模块传参 & 回调 Caller 页面
    private static func registerRouterCaller() {
        BARouter.shared.register(BADemoRoute.Foundation.routerCaller, title: "跨模块传参 & 回调", sourceType: .push) { _ in
            BARouterCallerViewController()
        }
    }
}
