//
//  BARouteModule.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

import Foundation

// MARK: - Route Module Protocol

/// 组件路由模块协议 —— 面向大型工程（上百组件）的推荐接入方式。
///
/// 每个业务组件（pod / module）实现一个遵循本协议的类，并在 `registerRoutes()`
/// 中集中注册本模块的全部路由。框架在 App 启动时通过
/// `BARouteRegistrarRegistry.shared.registerAll()` 自动发现并调用，
/// **主工程代码不随组件增减而改动**。
///
/// ## 为什么用 `@objc` + 类方法（相比旧版 `BARouteRegistrar`）
///
/// 旧的实例式注册器为了被 Runtime 发现，框架不得不 `init()` 实例化每一个被扫描到的类
/// 来测试协议遵循 —— 在上百组件 + 系统/三方类的进程里既慢又危险（无差别实例化
/// 系统类可能产生副作用甚至崩溃）。本协议改为 **`@objc` 标记 + 静态方法**，带来两点关键收益：
///
/// 1. **零实例化发现**：框架用 `cls as? BARouteModule.Type` 在不创建任何实例的前提下
///    判断类是否为注册器，并直接调用其类方法，彻底规避实例化风险与开销。
/// 2. **仅扫描 App 自身镜像**：发现过程通过 `class_getImageName` 过滤，只遍历主程序与
///    其内嵌 Framework 中的类，跳过系统库 / 三方库，启动开销与「组件数量」线性相关且常数极小。
///
/// ## 使用方式
///
/// ```swift
/// // 在组件 Pod 内部新增一个 Router 类即可（无需任何构建配置）：
/// @objc(BAUserModuleRouter)
/// final class BAUserModuleRouter: NSObject, BARouteModule {
///     static func registerRoutes() {
///         // 极简注册：闭包返回目标 VC，框架自动完成 参数注入 → 导航 → 回调
///         BARouter.shared.register("/user/profile") { _ in
///             UserProfileViewController()
///         }
///         BARouter.shared.register("/user/detail/:userId", sourceType: .push) { params in
///             UserDetailViewController(userId: params.string("userId"))
///         }
///     }
/// }
/// ```
///
/// ## AppDelegate 一键启动（永不改动）
///
/// ```swift
/// func application(_ application: UIApplication,
///                  didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
///     BARouter.shared.setup(autoRegister: true)   // 自动发现并注册所有 BARouteModule
///     return true
/// }
/// ```
///
/// - Important: 实现类必须继承 `NSObject` 并标记 `@objc(类名)`，否则无法被 Runtime 发现。
/// - Note: `registerRoutes()` 在 App 启动阶段同步调用，请勿在其中做耗时操作或访问 UI 层级。
@objc public protocol BARouteModule {

    /// 注册本模块的全部路由。
    ///
    /// 框架在 App 启动时自动调用（类方法，**无需实例化**）。
    /// 在此方法内通过 `BARouter.shared.register(...)` 逐条注册路由，
    /// 建议按业务拆分为多个 `private static` 方法以保持可读性。
    @objc static func registerRoutes()
}
