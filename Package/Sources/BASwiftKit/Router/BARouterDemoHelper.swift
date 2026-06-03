//
//  BARouterDemoHelper.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

#if canImport(UIKit)
import UIKit

// MARK: - Demo Helper

/// 路由组件示例辅助工具。
///
/// 提供快速创建示例路由注册的便捷方法，方便在 Demo 工程中
/// 测试路由跳转、参数注入、拦截器等完整链路。
public enum BARouterDemoHelper {

    /// 注册一组示例路由（供 Demo 调试）。
    public static func registerDemoRoutes() {
        // 示例：用户详情页路由
        BARouter.shared.register(
            BARouteConfig(
                pattern: "/demo/user/:userId",
                targetType: .action({ params, completion in
                    let userId = params["userId"] as? String ?? "?"
                    BARouterLogger.info("Demo 路由 /demo/user/:userId → userId=\(userId)")
                    completion?()
                }),
                sourceType: .auto,
                animated: true
            )
        )

        // 示例：设置页路由
        BARouter.shared.register(
            BARouteConfig(
                pattern: "/demo/settings",
                targetType: .action({ params, completion in
                    BARouterLogger.info("Demo 路由 /demo/settings")
                    completion?()
                }),
                sourceType: .push,
                animated: true
            )
        )

        BARouterLogger.info("Demo 示例路由注册完成")
    }
}
#endif
