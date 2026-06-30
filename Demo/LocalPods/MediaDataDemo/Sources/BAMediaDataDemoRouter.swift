//
//  BAMediaDataDemoRouter.swift
//  MediaDataDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// Data & Image Demo 路由注册器。
///
/// 负责注册 Data & Image 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAMediaDataDemoRouter)
final class BAMediaDataDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/media-data", title: "Data & Image", sourceType: .push) { _ in
            BAMediaDataDemoViewController()
        }
    }
}
