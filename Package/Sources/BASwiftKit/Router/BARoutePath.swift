//
//  BARoutePath.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Typed Route Path

/// 类型安全的路由路径协议。
///
/// `BARouter` 的注册与跳转入口既接受原始字符串，也接受任何遵循本协议的类型——
/// 通常是 **String-backed enum**。用枚举代替散落字符串可获得：
///
/// - 编译期检查：path 写错（拼写、大小写）直接编译报错，而非运行时静默 404；
/// - 自动补全：`.userDetail` 一键补全，无需回忆路径段；
/// - 重命名安全：改一处 case 的 rawValue，所有引用同步生效；
/// - 集中治理：所有路由声明收敛在一处，便于审阅与去重。
///
/// ## 接入方式
///
/// 推荐用 String-backed enum，一行即可满足协议要求：
///
/// ```swift
/// enum AppRoute: String, BARoutePath {
///     case home     = "/home"
///     case settings = "/settings"
///     case userDetail = "/user/:userId"   // 仍支持 :param 与 *
///     var pattern: String { rawValue }
/// }
/// ```
///
/// 随后即可直接把枚举 case 传给 `BARouter`：
///
/// ```swift
/// BARouter.shared.register(AppRoute.settings, title: "设置") { _ in SettingsVC() }
/// BARouter.shared.open(AppRoute.settings)
/// ```
///
/// - Note: 协议只描述「静态声明的路由模式」。对于运行时动态拼装的 URL
///   （如 `/user/123?from=push`，带路径参数实例化与 query），仍应使用字符串入口
///   `open(_ url: String)`。
public protocol BARoutePath {
    /// 路由匹配模式，如 `"/demo/ui/color"` 或 `"/user/:userId"`。
    ///
    /// 支持与字符串入口完全一致的 Pattern 语法：`:paramName` 路径参数、`*` 通配。
    var pattern: String { get }
}

// MARK: - BARouter + Typed Overloads

public extension BARouter {

    /// 通过类型安全的路由枚举发起跳转。
    ///
    /// 等价于 `open(_ url: String)`，只是入参由字符串换成了 `BARoutePath`。
    /// 内部取 `path.pattern` 走原有字符串链路，匹配逻辑零改动。
    ///
    /// - Parameters:
    ///   - path: 路由枚举（遵循 `BARoutePath`）。
    ///   - completion: 跳转完成回调。`error` 为 `nil` 表示成功。
    ///
    /// ```swift
    /// BARouter.shared.open(AppRoute.settings) { error in
    ///     if let error = error { print("路由失败: \(error)") }
    /// }
    /// ```
    @discardableResult
    func open(_ path: BARoutePath, completion: ((BARouteError?) -> Void)? = nil) -> BARouteError? {
        open(path.pattern, completion: completion)
    }
}

#if canImport(UIKit)
public extension BARouter {

    /// 极简注册的类型安全重载 —— 面向「上百组件快速接入」的首选 API。
    ///
    /// 与字符串版极简注册行为完全一致，仅把首个入参从字符串换成 `BARoutePath`，
    /// 便于用枚举声明路由。
    ///
    /// - Parameters:
    ///   - path: 路由枚举（遵循 `BARoutePath`）。
    ///   - title: 目标页标题，非 `nil` 时自动赋给 `viewController.title`。
    ///   - sourceType: 导航方式，默认 `.auto`（有导航栈则 push，否则 present）。
    ///   - animated: 是否带转场动画，默认 `true`。
    ///   - hidesBottomBar: push 时是否隐藏底部 TabBar，默认 `true`。
    ///   - interceptors: 该路由专属拦截器，默认空。
    ///   - builder: 目标 VC 构造闭包。返回 `nil` 视为构造失败，`completion` 收到 `.parameterError`。
    ///
    /// ```swift
    /// BARouter.shared.register(AppRoute.userDetail, sourceType: .push) { params in
    ///     UserDetailViewController(userId: params.string("userId"))
    /// }
    /// ```
    func register(
        _ path: BARoutePath,
        title: String? = nil,
        sourceType: BARouteSourceType = .auto,
        animated: Bool = true,
        hidesBottomBar: Bool = true,
        interceptors: [BARouteInterceptor] = [],
        builder: @escaping (BARouteParams) -> UIViewController?
    ) {
        register(
            path.pattern,
            title: title,
            sourceType: sourceType,
            animated: animated,
            hidesBottomBar: hidesBottomBar,
            interceptors: interceptors,
            builder: builder
        )
    }
}
#endif
