//
//  BAServiceable.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Service Protocol

/// 路由服务协议。
///
/// 所有需要通过路由容器进行 IoC 注入的服务协议必须继承此协议。
///
/// ```swift
/// protocol UserServiceProtocol: BAServiceable {
///     func login(phone: String, code: String) async throws -> User
/// }
/// ```
public protocol BAServiceable: AnyObject {}

// MARK: - Service Registry

/// 服务注册条目。
struct BAServiceEntry {
    /// 服务协议类型（用于匹配查询）。
    let protocolType: ObjectIdentifier
    /// 服务工厂闭包：每次 resolve 时调用。
    let creator: () -> AnyObject
    /// 是否单例模式（仅创建一次）。
    let isSingleton: Bool
    /// 单例缓存。
    var cachedInstance: AnyObject?
}

// MARK: - Service Container

/// IoC 服务容器。
///
/// 负责服务的注册与解析，支持单例/工厂两种生命周期。
final class BAServiceContainer {
    private let lock = NSLock()
    private var entries: [ObjectIdentifier: BAServiceEntry] = [:]

    // MARK: - Register

    /// 注册一个服务的工厂方法。
    ///
    /// - Parameters:
    ///   - type: 服务协议类型。
    ///   - isSingleton: 是否单例（仅创建一次），默认 `true`。
    ///   - creator: 工厂闭包，`resolve` 时调用。
    ///
    /// ```swift
    /// container.register(UserServiceProtocol.self, isSingleton: true) {
    ///     UserServiceImpl()
    /// }
    /// ```
    func register<T: BAServiceable>(
        _ type: T.Type,
        isSingleton: Bool = true,
        creator: @escaping () -> T
    ) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        entries[key] = BAServiceEntry(
            protocolType: key,
            creator: { creator() },
            isSingleton: isSingleton,
            cachedInstance: nil
        )
    }

    // MARK: - Resolve

    /// 解析并获取服务实例。
    ///
    /// - Parameter type: 服务协议类型。
    /// - Returns: 服务实例，若未注册则返回 `nil`。
    ///
    /// ```swift
    /// let userService = container.resolve(UserServiceProtocol.self)
    /// ```
    func resolve<T: BAServiceable>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        guard var entry = entries[key] else { return nil }

        if entry.isSingleton {
            if let cached = entry.cachedInstance {
                return cached as? T
            }
            let instance = entry.creator()
            entry.cachedInstance = instance
            entries[key] = entry
            return instance as? T
        }

        return entry.creator() as? T
    }

    // MARK: - Remove

    /// 移除指定服务的注册。
    ///
    /// - Parameter type: 服务协议类型。
    func remove<T: BAServiceable>(_ type: T.Type) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        entries.removeValue(forKey: key)
    }

    /// 清空全部服务注册。
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }
}
