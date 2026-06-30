//
//  BANetworkCryptoDemoRouter.swift
//  NetworkCryptoDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// Network & Crypto Demo 路由注册器。
///
/// 负责注册 Network & Crypto 演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BANetworkCryptoDemoRouter)
final class BANetworkCryptoDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register(BADemoRoute.Foundation.networkCrypto, title: "Network & Crypto", sourceType: .push) { _ in
            BANetworkCryptoDemoViewController(viewModel: BANetworkCryptoDemoViewModel())
        }
    }
}
