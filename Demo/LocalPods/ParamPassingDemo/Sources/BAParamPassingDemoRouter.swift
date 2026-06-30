//
//  BAParamPassingDemoRouter.swift
//  ParamPassingDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 参数传递 & 回调 Demo 路由注册器。
///
/// 负责注册参数传递与回调演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAParamPassingDemoRouter)
final class BAParamPassingDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.paramPassing, title: "参数传递 & 回调", sourceType: .push) { params in
            let token = params["_ba_callback_token"] as? BARouteCallbackToken
            return BAParamPassingDemoViewController(routeToken: token)
        }
    }
}
