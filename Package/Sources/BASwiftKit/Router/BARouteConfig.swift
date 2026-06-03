//
//  BARouteConfig.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Route Target Type

/// 路由目标类型：区分页面跳转和服务调用。
public enum BARouteTargetType {
    /// 跳转到 UIViewController。
    /// - Parameter type: 目标 VC 类型。
    case viewController(UIViewController.Type)

    /// 打开一个 Action 闭包（不创建 VC）。
    /// - Parameter handler: 自定义处理闭包，接收解析后的参数和完成回调。
    case action((_ params: [String: Any], _ completion: (() -> Void)?) -> Void)
}

// MARK: - Route Source Type

/// 路由来源类型，用于区分导航方式。
public enum BARouteSourceType {
    /// 由调用方自行决定（默认 push，无法 push 时 fallback 到 present）。
    case auto

    /// Push 进入导航栈（需要调用方有 UINavigationController）。
    case push

    /// Modal 弹出。
    case present

    /// 设为 Window 根控制器。
    case root
}

// MARK: - Route Config

/// 路由注册配置。
///
/// 每条路由对应一个 URL Pattern 和一个目标：
///
/// ```swift
/// let config = BARouteConfig(
///     pattern: "/user/detail/:userId",
///     targetType: .viewController(UserDetailVC.self),
///     sourceType: .push,
///     animated: true,
///     interceptors: [LoginInterceptor()]
/// )
/// ```
public struct BARouteConfig {

    // MARK: - Properties

    /// URL 匹配模式，支持路径参数 `:paramName` 和通配符 `*`。
    ///
    /// 示例：
    /// - `/user/detail/:userId` → 匹配 `/user/detail/123`，参数 `{"userId": "123"}`
    /// - `/web/*` → 匹配 `/web/任意路径`
    public let pattern: String

    /// 路由目标类型（页面跳转 / 自定义动作）。
    public let targetType: BARouteTargetType

    /// 导航方式，默认 `.auto`（由框架自动判断）。
    public let sourceType: BARouteSourceType

    /// 跳转是否带动画，默认 `true`。
    public let animated: Bool

    /// 该路由专属的拦截器列表（在全局拦截器之后执行）。
    public let interceptors: [BARouteInterceptor]

    // MARK: - Init

    /// 创建一条路由配置。
    ///
    /// - Parameters:
    ///   - pattern: URL 匹配模式。
    ///   - targetType: 目标类型（VC 或 Action）。
    ///   - sourceType: 导航方式，默认 `.auto`。
    ///   - animated: 是否带动画，默认 `true`。
    ///   - interceptors: 专属拦截器列表，默认空。
    public init(
        pattern: String,
        targetType: BARouteTargetType,
        sourceType: BARouteSourceType = .auto,
        animated: Bool = true,
        interceptors: [BARouteInterceptor] = []
    ) {
        self.pattern = pattern
        self.targetType = targetType
        self.sourceType = sourceType
        self.animated = animated
        self.interceptors = interceptors
    }
}

// MARK: - Route Match Result

/// 路由匹配结果，包含解析后的参数和路由配置。
public struct BARouteMatchResult {
    /// 匹配到的路由配置。
    public let config: BARouteConfig
    /// 从 URL 路径中解析出的参数字典。
    ///
    /// 示例：`/user/detail/123?from=home` → `["userId": "123", "from": "home"]`
    public let params: [String: Any]
}
