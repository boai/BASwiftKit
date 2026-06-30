//
//  BALoadingDemoRouter.swift
//  LoadingDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 加载 HUD Demo 路由注册器。
///
/// 负责注册加载 HUD / Progress 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BALoadingDemoRouter)
final class BALoadingDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/feedback/loading", title: "加载 HUD / Progress", sourceType: .push) { _ in
            BALoadingDemoViewController(viewModel: BALoadingDemoViewModel())
        }
    }
}
