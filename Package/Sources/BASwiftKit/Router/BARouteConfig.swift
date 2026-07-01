//
//  BARouteConfig.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Route Source Type

/// 路由来源类型，用于区分导航方式。
///
/// - `.auto`: 跨平台，由 Handler 自行决定导航方式（推荐用于 SwiftUI / AppKit）。
/// - `.push`: UIKit 专用，Push 进入 UINavigationController 栈。
/// - `.present`: UIKit 专用，Modal 弹出。
/// - `.root`: UIKit 专用，设为 Window 根控制器。
public enum BARouteSourceType {
    /// 跨平台，由 Handler 自行决定导航方式（推荐用于 SwiftUI / AppKit）。
    case auto

    /// UIKit 专用，Push 进入导航栈（需要调用方有 UINavigationController）。
    case push

    /// UIKit 专用，Modal 弹出。
    case present

    /// UIKit 专用，设为 Window 根控制器。
    case root
}

// MARK: - Route Config

/// 路由注册配置。
///
/// 每条路由对应一个 URL Pattern 和一个 `BARouteHandler`：
///
/// ```swift
/// let config = BARouteConfig(
///     pattern: "/user/detail/:userId",
///     handler: UserDetailRouteHandler(),
///     sourceType: .push,
///     animated: true,
///     interceptors: [LoginInterceptor()]
/// )
/// ```
///
/// ## 设计理念
///
/// 路由配置不再直接持有 `UIViewController.Type`，改为持有 `BARouteHandler` 协议实例。
/// BARouter 匹配到路由后，将跳转逻辑完全委托给 Handler，框架层零 UIKit 耦合。
public struct BARouteConfig {

    // MARK: - Properties

    /// URL 匹配模式，支持路径参数 `:paramName` 和通配符 `*`。
    ///
    /// 示例：
    /// - `/user/detail/:userId` → 匹配 `/user/detail/123`，参数 `{"userId": "123"}`
    /// - `/web/*` → 匹配 `/web/任意路径`
    public let pattern: String

    /// 路由处理器（负责创建目标页面并执行导航跳转）。
    ///
    /// BARouter 匹配到 URL 后，将参数和控制权交给此 Handler，
    /// 框架本身不再直接创建 UIViewController。
    public let handler: BARouteHandler

    /// 导航方式，默认 `.auto`（由 Handler 自行判断）。
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
    ///   - handler: 路由处理器（遵循 `BARouteHandler` 协议）。
    ///   - sourceType: 导航方式，默认 `.auto`。
    ///   - animated: 是否带动画，默认 `true`。
    ///   - interceptors: 专属拦截器列表，默认空。
    public init(
        pattern: String,
        handler: BARouteHandler,
        sourceType: BARouteSourceType = .auto,
        animated: Bool = true,
        interceptors: [BARouteInterceptor] = []
    ) {
        self.pattern = pattern
        self.handler = handler
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
