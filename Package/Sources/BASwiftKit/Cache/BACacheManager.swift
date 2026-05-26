//
//  BACacheManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 缓存管理器：提供统一接口管理多种缓存策略。
///
/// `BACacheManager` 是一个单例管理器，预置了三种常用缓存策略：
/// - `.default`：混合缓存（内存 + 磁盘），兼顾速度和持久化
/// - `.memoryOnly`：仅内存缓存，适合临时数据
/// - `.diskOnly`：仅磁盘缓存，适合大文件或需要长期保存的数据
///
/// 同时也支持自定义 `BAMemoryCache` / `BADiskCache` / `BAHybridCache` 实例注入。
///
/// ```swift
/// // 模型缓存（自动序列化）
/// BACacheManager.default.ba_setObject(user, forKey: "current_user")
/// let user = BACacheManager.default.ba_object(forKey: "current_user", type: User.self)
///
/// // 原始数据缓存
/// BACacheManager.default.ba_set(imageData, forKey: "avatar")
/// let imageData = BACacheManager.default.ba_data(forKey: "avatar")
///
/// // 字符串缓存
/// BACacheManager.default.ba_setString("token", forKey: "api_token")
/// let token = BACacheManager.default.ba_string(forKey: "api_token")
/// ```
public final class BACacheManager {

    /// 默认混合缓存策略（内存 + 磁盘）。
    public static let `default` = BACacheManager(strategy: .hybrid)

    /// 仅内存缓存策略。
    public static let memoryOnly = BACacheManager(strategy: .memory)

    /// 仅磁盘缓存策略。
    public static let diskOnly = BACacheManager(strategy: .disk)

    /// 当前管理器使用的缓存策略。
    public let strategy: BACacheStrategy

    private let memoryCache: BAMemoryCache?
    private let diskCache: BADiskCache?
    private let hybridCache: BAHybridCache?

    /// 缓存策略类型。
    public enum BACacheStrategy {
        /// 混合缓存（内存 + 磁盘）。
        case hybrid
        /// 仅内存缓存。
        case memory
        /// 仅磁盘缓存。
        case disk
    }

    /// 创建缓存管理器。
    ///
    /// - Parameters:
    ///   - strategy: 缓存策略，默认 `.hybrid`。
    ///   - memoryCache: 自定义内存缓存实例。若传 `nil` 则根据策略自动创建。
    ///   - diskCache: 自定义磁盘缓存实例。若传 `nil` 则根据策略自动创建。
    ///   - hybridCache: 自定义混合缓存实例。若传 `nil` 则根据策略自动创建。
    public init(strategy: BACacheStrategy = .hybrid,
                memoryCache: BAMemoryCache? = nil,
                diskCache: BADiskCache? = nil,
                hybridCache: BAHybridCache? = nil) {
        self.strategy = strategy
        switch strategy {
        case .hybrid:
            self.hybridCache = hybridCache ?? BAHybridCache()
            self.memoryCache = nil
            self.diskCache = nil
        case .memory:
            self.memoryCache = memoryCache ?? BAMemoryCache()
            self.diskCache = nil
            self.hybridCache = nil
        case .disk:
            self.diskCache = diskCache ?? BADiskCache()
            self.memoryCache = nil
            self.hybridCache = nil
        }
    }

    // MARK: - Data

    /// 存储二进制数据。
    ///
    /// - Parameters:
    ///   - data: 要缓存的二进制数据。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_set(_ data: Data, forKey key: String, expiry: Date = .distantFuture) {
        switch strategy {
        case .hybrid:
            hybridCache?.ba_set(data, forKey: key, expiry: expiry)
        case .memory:
            memoryCache?.ba_set(data, forKey: key, expiry: expiry)
        case .disk:
            diskCache?.ba_set(data, forKey: key, expiry: expiry)
        }
    }

    /// 读取二进制数据。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的二进制数据，若不存在或已过期则返回 `nil`。
    public func ba_data(forKey key: String) -> Data? {
        switch strategy {
        case .hybrid:
            return hybridCache?.ba_data(forKey: key)
        case .memory:
            return memoryCache?.ba_data(forKey: key)
        case .disk:
            return diskCache?.ba_data(forKey: key)
        }
    }

    // MARK: - Codable Model

    /// 存储模型对象（自动 `Codable` 序列化）。
    ///
    /// - Parameters:
    ///   - object: 遵循 `Codable` 的模型对象。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setObject<T: Encodable>(_ object: T, forKey key: String, expiry: Date = .distantFuture) {
        switch strategy {
        case .hybrid:
            hybridCache?.ba_setObject(object, forKey: key, expiry: expiry)
        case .memory:
            memoryCache?.ba_setObject(object, forKey: key, expiry: expiry)
        case .disk:
            diskCache?.ba_setObject(object, forKey: key, expiry: expiry)
        }
    }

    /// 读取并解码为模型。
    ///
    /// - Parameters:
    ///   - key: 缓存标识。
    ///   - type: 目标模型类型。
    /// - Returns: 解码后的模型，若不存在、已过期或解码失败则返回 `nil`。
    public func ba_object<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        switch strategy {
        case .hybrid:
            return hybridCache?.ba_object(forKey: key, type: type)
        case .memory:
            return memoryCache?.ba_object(forKey: key, type: type)
        case .disk:
            return diskCache?.ba_object(forKey: key, type: type)
        }
    }

    // MARK: - String

    /// 存储字符串。
    ///
    /// - Parameters:
    ///   - string: 要缓存的字符串。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setString(_ string: String, forKey key: String, expiry: Date = .distantFuture) {
        guard let data = string.data(using: .utf8) else { return }
        ba_set(data, forKey: key, expiry: expiry)
    }

    /// 读取字符串。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的字符串，若不存在或已过期则返回 `nil`。
    public func ba_string(forKey key: String) -> String? {
        guard let data = ba_data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Common Operations

    /// 删除指定 key 的缓存。
    ///
    /// - Parameter key: 缓存标识。
    public func ba_remove(forKey key: String) {
        switch strategy {
        case .hybrid:
            hybridCache?.ba_remove(forKey: key)
        case .memory:
            memoryCache?.ba_remove(forKey: key)
        case .disk:
            diskCache?.ba_remove(forKey: key)
        }
    }

    /// 清空全部缓存。
    public func ba_clear() {
        switch strategy {
        case .hybrid:
            hybridCache?.ba_clear()
        case .memory:
            memoryCache?.ba_clear()
        case .disk:
            diskCache?.ba_clear()
        }
    }

    /// 判断是否包含指定 key 的缓存（且未过期）。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 若存在且未过期返回 `true`。
    public func ba_contains(forKey key: String) -> Bool {
        ba_data(forKey: key) != nil
    }

    /// 当前磁盘缓存总大小（字节）。
    /// 若策略为 `.memory`，始终返回 `0`。
    public func ba_totalDiskSize() -> Int64 {
        switch strategy {
        case .hybrid:
            return hybridCache?.ba_totalDiskSize() ?? 0
        case .memory:
            return 0
        case .disk:
            return diskCache?.ba_totalSize() ?? 0
        }
    }

    /// 异步清理所有已过期条目。
    ///
    /// - Parameter completion: 清理完成后在主线程回调。
    public func ba_cleanExpired(completion: (() -> Void)? = nil) {
        switch strategy {
        case .hybrid:
            hybridCache?.ba_cleanExpired(completion: completion)
        case .memory:
            memoryCache?.ba_clear()
            completion?()
        case .disk:
            diskCache?.ba_cleanExpired(completion: completion)
        }
    }
}
