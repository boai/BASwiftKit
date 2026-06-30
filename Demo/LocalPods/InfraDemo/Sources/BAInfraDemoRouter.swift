//
//  BAInfraDemoRouter.swift
//  InfraDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit
import DemoCommon

/// 基础设施 Demo 路由注册器。
///
/// 负责注册 EmptyView、自定义 Alert、基础设施等演示页面的路由。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAInfraDemoRouter)
final class BAInfraDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        registerEmptyViewPage()
        registerAlertPage()
        registerInfraPage()
    }

    // MARK: - EmptyView / 空状态

    private static func registerEmptyViewPage() {
        BARouter.shared.register(BADemoRoute.Feedback.emptyView, title: "EmptyView / 空状态", sourceType: .push) { _ in
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        }
    }

    // MARK: - 自定义 Alert / 表单

    private static func registerAlertPage() {
        BARouter.shared.register(BADemoRoute.Feedback.alert, title: "自定义 Alert / 表单", sourceType: .push) { _ in
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        }
    }

    // MARK: - 基础设施 / Codable · Network

    private static func registerInfraPage() {
        BARouter.shared.register(BADemoRoute.Foundation.infra, title: "基础设施 / Codable · Network", sourceType: .push) { _ in
            BAInfraDemoViewController(viewModel: BAInfraDemoViewModel())
        }
    }
}
