//
//  BAAnimationDemoRouter.swift
//  AnimationDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 动画 Demo 路由注册器。
///
/// 负责注册动画演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAAnimationDemoRouter)
final class BAAnimationDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/ui/animation", title: "动画 / Animation", sourceType: .push) { _ in
            BAAnimationDemoViewController(viewModel: BAAnimationDemoViewModel())
        }
    }
}
