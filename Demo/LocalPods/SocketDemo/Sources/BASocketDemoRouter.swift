//
//  BASocketDemoRouter.swift
//  SocketDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// Socket Demo 路由注册器。
///
/// 负责注册 Socket / WebSocket 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BASocketDemoRouter)
final class BASocketDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.socket, title: "Socket / WebSocket", sourceType: .push) { _ in
            BASocketDemoViewController()
        }
    }
}
