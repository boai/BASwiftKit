//
//  BAFontDemoRouter.swift
//  FontDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 字体 Demo 路由注册器。
///
/// 负责注册字体演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAFontDemoRouter)
final class BAFontDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/ui/font", title: "字体 / UIFont", sourceType: .push) { _ in
            BAFontDemoViewController(viewModel: BAFontDemoViewModel())
        }
    }
}
