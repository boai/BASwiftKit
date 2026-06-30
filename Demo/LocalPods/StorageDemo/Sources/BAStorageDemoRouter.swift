//
//  BAStorageDemoRouter.swift
//  StorageDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// Storage 存储 Demo 路由注册器。
///
/// 负责注册存储演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAStorageDemoRouter)
final class BAStorageDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/storage", title: "Storage 存储工具", sourceType: .push) { _ in
            BAStorageDemoViewController(viewModel: BAStorageDemoViewModel())
        }
    }
}
