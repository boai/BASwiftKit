//
//  BARouteHandler.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Route Handler Protocol

/// 路由处理器协议。
///
/// 每个路由注册时绑定一个 Handler 实例，BARouter 匹配到路由后，
/// 将跳转逻辑完全委托给 Handler，**路由框架不再直接操作 UIViewController**。
///
/// ## 设计理念（参考 CTMediator）
///
/// - BARouter 只负责 URL 匹配 + 拦截器链 + 回调管理
/// - Handler 负责目标页面的创建、参数注入、导航跳转
/// - 框架层零 UIKit 耦合，所有 VC 操作由 Handler 自行处理
///
/// ## 使用方式
///
/// ```swift
/// // 1. 实现 Handler
/// final class UserDetailRouteHandler: BARouteHandler {
///     func handle(
///         params: [String: Any],
///         sourceType: BARouteSourceType,
///         animated: Bool,
///         completion: @escaping (BARouteError?) -> Void
///     ) {
///         let vc = UserDetailViewController()
///         vc.receiveRouteParams(params)
///         BARouteNavigator.push(vc, sourceType: sourceType, animated: animated)
///         completion(nil)
///     }
/// }
///
/// // 2. 注册时绑定
/// BARouter.shared.register(
///     BARouteConfig(
///         pattern: "/user/detail/:userId",
///         handler: UserDetailRouteHandler()
///     )
/// )
/// ```
public protocol BARouteHandler: AnyObject {

    /// 处理路由跳转。
    ///
    /// 路由框架匹配 URL 并通过拦截器链后，调用此方法将控制权交给业务层。
    /// 业务层在此方法中完成：
    /// 1. 创建目标 ViewController
    /// 2. 注入路由参数
    /// 3. 执行导航跳转（push / present / root）
    /// 4. 调用 `completion` 通知框架跳转结果
    ///
    /// - Parameters:
    ///   - params: URL 解析出的参数字典（路径参数 + Query 参数合并）。
    ///   - sourceType: 导航方式（auto / push / present / root）。
    ///   - animated: 是否带动画。
    ///   - completion: 跳转完成回调，传入 `nil` 表示成功，传入 `BARouteError` 表示失败。
    func handle(
        params: [String: Any],
        sourceType: BARouteSourceType,
        animated: Bool,
        completion: @escaping (BARouteError?) -> Void
    )
}
