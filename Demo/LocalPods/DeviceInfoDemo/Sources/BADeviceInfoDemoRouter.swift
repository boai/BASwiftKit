//
//  BADeviceInfoDemoRouter.swift
//  DeviceInfoDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 设备信息 Demo 路由注册器。
///
/// 负责注册设备信息演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BADeviceInfoDemoRouter)
final class BADeviceInfoDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        BARouter.shared.register("/demo/foundation/device-info", title: "设备信息 + 清缓存", sourceType: .push) { _ in
            BADeviceInfoDemoViewController(viewModel: BADeviceInfoDemoViewModel())
        }
    }
}
