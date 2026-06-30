//
//  BARouterDemoHelper.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

#if canImport(UIKit)
import UIKit

// MARK: - Closure-Based Handler

/// 基于闭包的路由处理器（轻量级 Handler，无需单独建类）。
///
/// 适用于简单的路由跳转场景，直接用闭包完成 VC 创建和导航，
/// 无需为每条路由单独创建一个 Handler 类。
///
/// ```swift
/// BARouter.shared.register(
///     BARouteConfig(
///         pattern: "/demo/test",
///         handler: BAClosureRouteHandler { params, sourceType, animated, completion in
///             let vc = TestViewController()
///             BARouteNavigator.navigate(vc, sourceType: sourceType, animated: animated)
///             completion(nil)
///         }
///     )
/// )
/// ```
public final class BAClosureRouteHandler: BARouteHandler {

    /// 处理闭包类型。
    public typealias HandlerBlock = (
        _ params: [String: Any],
        _ sourceType: BARouteSourceType,
        _ animated: Bool,
        _ completion: @escaping (BARouteError?) -> Void
    ) -> Void

    private let block: HandlerBlock

    /// 创建一个基于闭包的路由处理器。
    ///
    /// - Parameter block: 路由处理闭包，接收参数、导航方式、动画标记和完成回调。
    public init(_ block: @escaping HandlerBlock) {
        self.block = block
    }

    public func handle(
        params: [String: Any],
        sourceType: BARouteSourceType,
        animated: Bool,
        completion: @escaping (BARouteError?) -> Void
    ) {
        block(params, sourceType, animated, completion)
    }
}

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
                handler: BAClosureRouteHandler { params, _, _, completion in
                    let userId = params["userId"] as? String ?? "?"
                    BARouterLogger.info("Demo 路由 /demo/user/:userId → userId=\(userId)")
                    completion(nil)
                },
                sourceType: .auto,
                animated: true
            )
        )

        // 示例：设置页路由
        BARouter.shared.register(
            BARouteConfig(
                pattern: "/demo/settings",
                handler: BAClosureRouteHandler { params, _, _, completion in
                    BARouterLogger.info("Demo 路由 /demo/settings")
                    completion(nil)
                },
                sourceType: .push,
                animated: true
            )
        )

        BARouterLogger.info("Demo 示例路由注册完成")
    }
}
#endif
