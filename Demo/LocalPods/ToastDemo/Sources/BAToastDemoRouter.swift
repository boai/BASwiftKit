//
//  BAToastDemoRouter.swift
//  ToastDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 全局 Toast Demo 路由注册器。
///
/// 负责注册 Toast 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAToastDemoRouter)
final class BAToastDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/feedback/toast", title: "全局 Toast", sourceType: .push) { _ in
            BAToastDemoViewController(viewModel: BAToastDemoViewModel())
        }
    }
}
