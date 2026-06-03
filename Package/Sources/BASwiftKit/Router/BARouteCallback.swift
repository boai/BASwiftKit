//
//  BARouteCallback.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Route Callback Identifier

/// 路由回调令牌，用于标识一次路由跳转的回调。
///
/// 发起方持有该令牌，目标页面通过 `BARouter.sendCallback(...)` 回传结果，
/// 发起方在回调闭包中接收结果。
///
/// ```swift
/// // 发起方
/// let token = BARouter.shared.open("/demo/param?name=hello") { result in
///     print("回调结果: \(result ?? "nil")")
/// }
///
/// // 目标页
/// BARouter.shared.sendCallback("操作成功", for: routeToken)
/// ```
public typealias BARouteCallbackToken = String

/// 路由回调闭包类型。
/// - Parameter result: 回调结果，可为 `nil`。
public typealias BARouteCallback = (Any?) -> Void

// MARK: - Callback Registry

/// 路由回调注册中心（内部使用）。
///
/// 管理路由回调的注册、查找和清理，确保回调生命周期安全。
final class BARouteCallbackRegistry {

    /// 回调存储。
    private var store: [BARouteCallbackToken: BARouteCallback] = [:]
    private let lock = NSLock()

    /// 注册一个回调，返回 token。
    func register(_ callback: @escaping BARouteCallback) -> BARouteCallbackToken {
        lock.lock()
        defer { lock.unlock() }
        let token = UUID().uuidString
        store[token] = callback
        return token
    }

    /// 查找并移除回调（单次触发）。
    func consume(_ token: BARouteCallbackToken) -> BARouteCallback? {
        lock.lock()
        defer { lock.unlock() }
        let cb = store[token]
        store.removeValue(forKey: token)
        return cb
    }

    /// 移除指定回调。
    func remove(_ token: BARouteCallbackToken) {
        lock.lock()
        defer { lock.unlock() }
        store.removeValue(forKey: token)
    }

    /// 清空所有回调。
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        store.removeAll()
    }
}
