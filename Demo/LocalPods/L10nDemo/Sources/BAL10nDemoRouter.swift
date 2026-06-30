//
//  BAL10nDemoRouter.swift
//  L10nDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 多语言 Demo 路由注册器。
///
/// 负责注册多语言 / BALocalization 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAL10nDemoRouter)
final class BAL10nDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.l10n, title: "多语言 / BALocalization", sourceType: .push) { _ in
            BAL10nDemoViewController(viewModel: BAL10nDemoViewModel())
        }
    }
}
