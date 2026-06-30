//
//  BAStringDemoRouter.swift
//  StringDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 字符串 Demo 路由注册器。
///
/// 负责注册字符串演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAStringDemoRouter)
final class BAStringDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/string", title: "字符串 / String", sourceType: .push) { _ in
            BAStringDemoViewController(viewModel: BAStringDemoViewModel())
        }
    }
}
