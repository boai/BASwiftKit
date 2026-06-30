//
//  BAScannerDemoRouter.swift
//  ScannerDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 扫一扫 Demo 路由注册器。
///
/// 负责注册扫码演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAScannerDemoRouter)
final class BAScannerDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.scanner, title: "扫一扫 / Scanner", sourceType: .push) { _ in
            BAScannerDemoViewController()
        }
    }
}
