//
//  BAWebViewDemoRouter.swift
//  WebViewDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// WebView 封装 Demo 路由注册器。
///
/// 负责注册 WebView 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAWebViewDemoRouter)
final class BAWebViewDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.webView, title: "WebView 封装", sourceType: .push) { _ in
            BAWebViewDemoViewController()
        }
    }
}
