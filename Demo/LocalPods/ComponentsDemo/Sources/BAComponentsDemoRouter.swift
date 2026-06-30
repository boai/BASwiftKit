//
//  BAComponentsDemoRouter.swift
//  ComponentsDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// UI 组件 Demo 路由注册器。
///
/// 负责注册 UI 组件演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAComponentsDemoRouter)
final class BAComponentsDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/ui/components", title: "UI 组件", sourceType: .push) { _ in
            BAComponentsDemoViewController(viewModel: BAComponentsDemoViewModel())
        }
    }
}
