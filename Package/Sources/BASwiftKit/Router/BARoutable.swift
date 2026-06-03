//
//  BARoutable.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Routable Protocol

/// 可路由页面协议。
///
/// 遵循该协议的 UIViewController 可以接收路由参数的注入。
/// 路由跳转时，框架会自动调用 `receiveRouteParams(_:)` 将 URL 参数传入目标页面。
///
/// ```swift
/// class UserDetailViewController: UIViewController, BARoutable {
///     func receiveRouteParams(_ params: [String : Any]) {
///         self.userId = params["userId"] as? String ?? ""
///     }
/// }
/// ```
public protocol BARoutable: AnyObject {
    /// 接收路由参数。
    ///
    /// 路由跳转到目标页面时会回调此方法，将 URL 解析出的参数字典传入。
    /// 子类在此方法中完成属性赋值。
    ///
    /// - Parameter params: 路由参数（路径参数 + Query 参数合并）。
    func receiveRouteParams(_ params: [String: Any])
}

/// BARoutable 默认实现（空方法，子类按需重写）。
public extension BARoutable {
    func receiveRouteParams(_ params: [String: Any]) {
        // 默认空实现
    }
}
