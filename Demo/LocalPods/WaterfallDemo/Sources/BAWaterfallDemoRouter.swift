//
//  BAWaterfallDemoRouter.swift
//  WaterfallDemo
//
//  Created by boai on 2026/06/03.
//

import BASwiftKit

/// 瀑布流 Demo 路由注册器。
///
/// 负责注册瀑布流演示页面的路由（包含普通瀑布流和横向分页瀑布流）。
/// 遵循 `BARouteModule` 协议，由 `BARouteRegistrarRegistry` 自动发现并注册。
@objc(BAWaterfallDemoRouter)
final class BAWaterfallDemoRouter: NSObject, BARouteModule {

    static func registerRoutes() {
        registerWaterfallPage()
        registerPagedWaterfallPage()
    }

    // MARK: - 瀑布流 FlowLayout

    private static func registerWaterfallPage() {
        BARouter.shared.register("/demo/ui/waterfall", title: "瀑布流 FlowLayout", sourceType: .push) { _ in
            BAWaterfallDemoViewController()
        }
    }

    // MARK: - 横向分页瀑布流

    private static func registerPagedWaterfallPage() {
        BARouter.shared.register("/demo/ui/paged-waterfall", title: "横向分页瀑布流", sourceType: .push) { _ in
            BAPagedWaterfallDemoViewController()
        }
    }
}
