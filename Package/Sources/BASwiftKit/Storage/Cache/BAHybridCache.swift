//
//  BAHybridCache.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 混合缓存：内存 + 磁盘自动同步。
///
/// `BAHybridCache` 同时维护一份内存缓存和一份磁盘缓存，读取时优先查内存（速度快），
/// 未命中时查磁盘，磁盘命中后自动回填到内存；写入时同时写入内存和磁盘。
/// 适合需要兼顾读取速度和数据持久化的场景。
///
/// ```swift
/// let cache = BAHybridCache()
/// cache.ba_set(data, forKey: "user_session")
/// if let data = cache.ba_data(forKey: "user_session") {
///     // 优先从内存读取，miss 则从磁盘读取
/// }
/// ```
public final class BAHybridCache {

    /// 内存缓存实例。可直接访问以调整内存相关配置（如 `costLimit`、`countLimit`）。
    public let memoryCache: BAMemoryCache

    /// 磁盘缓存实例。可直接访问以调整磁盘相关配置（如 `sizeLimit`）。
    public let diskCache: BADiskCache

    /// 创建混合缓存实例。
    ///
    /// - Parameters:
    ///   - memoryCache: 内存缓存实例，默认创建新的 `BAMemoryCache`。
    ///   - diskCache: 磁盘缓存实例，默认创建新的 `BADiskCache`。
    public init(memoryCache: BAMemoryCache = BAMemoryCache(),
                diskCache: BADiskCache = BADiskCache()) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    // MARK: - Public API

    /// 将数据同时存入内存和磁盘缓存。
    ///
    /// - Parameters:
    ///   - data: 要缓存的二进制数据。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    ///   - cost: 存储成本，默认使用 `data.count`。
    public func ba_set(_ data: Data,
                       forKey key: String,
                       expiry: Date = .distantFuture,
                       cost: Int? = nil) {
        memoryCache.ba_set(data, forKey: key, expiry: expiry, cost: cost)
        diskCache.ba_set(data, forKey: key, expiry: expiry, cost: cost)
    }

    /// 从混合缓存读取数据。
    ///
    /// 读取优先级：内存 > 磁盘。若磁盘命中，会自动回填到内存以加速下次读取。
    /// 若条目已过期，读取时会自动删除并返回 `nil`。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的二进制数据，若不存在或已过期则返回 `nil`。
    public func ba_data(forKey key: String) -> Data? {
        if let data = memoryCache.ba_data(forKey: key) {
            return data
        }
        if let data = diskCache.ba_data(forKey: key) {
            memoryCache.ba_set(data, forKey: key)
            return data
        }
        return nil
    }

    /// 从混合缓存读取并解码为模型。
    ///
    /// - Parameters:
    ///   - key: 缓存标识。
    ///   - type: 目标模型类型。
    /// - Returns: 解码后的模型，若不存在、已过期或解码失败则返回 `nil`。
    public func ba_object<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        guard let data = ba_data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// 将模型编码后同时存入内存和磁盘缓存。
    ///
    /// - Parameters:
    ///   - object: 遵循 `Codable` 的模型对象。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setObject<T: Encodable>(_ object: T, forKey key: String, expiry: Date = .distantFuture) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        ba_set(data, forKey: key, expiry: expiry)
    }

    /// 将字符串以 UTF-8 编码同时存入内存和磁盘缓存。
    ///
    /// 等价于 `ba_set(string.data(using: .utf8), forKey: key)`，
    /// 但额外做了编码失败保护（UTF-8 对任意 Swift String 都能成功，仅作防御性兜底）。
    /// 适合缓存 token、配置项、短文本等，比走 `ba_setObject` 更直观，省去 JSON 包裹。
    ///
    /// ```swift
    /// cache.ba_setString("eyJhbGciOi...", forKey: "auth_token")
    /// cache.ba_setString("v2", forKey: "config_version", expiry: Date().addingTimeInterval(3600))
    /// ```
    ///
    /// - Parameters:
    ///   - string: 要缓存的字符串。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setString(_ string: String, forKey key: String, expiry: Date = .distantFuture) {
        guard let data = string.data(using: .utf8) else { return }
        ba_set(data, forKey: key, expiry: expiry)
    }

    /// 从混合缓存读取字符串（按 UTF-8 解码）。
    ///
    /// 读取优先级：内存 > 磁盘（与 `ba_data` 一致），磁盘命中后自动回填到内存。
    /// 若条目不存在、已过期或不是有效 UTF-8 数据，均返回 `nil`。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的字符串，若不存在/已过期/解码失败则返回 `nil`。
    public func ba_string(forKey key: String) -> String? {
        guard let data = ba_data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 删除指定 key 的内存和磁盘缓存。
    ///
    /// - Parameter key: 缓存标识。
    public func ba_remove(forKey key: String) {
        memoryCache.ba_remove(forKey: key)
        diskCache.ba_remove(forKey: key)
    }

    /// 清空全部内存和磁盘缓存。
    public func ba_clear() {
        memoryCache.ba_clear()
        diskCache.ba_clear()
    }

    /// 判断是否包含指定 key 的缓存（且未过期）。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 若存在且未过期返回 `true`。
    public func ba_contains(forKey key: String) -> Bool {
        ba_data(forKey: key) != nil
    }

    /// 当前磁盘缓存总大小（字节）。
    public func ba_totalDiskSize() -> Int64 {
        diskCache.ba_totalSize()
    }

    /// 异步清理所有已过期条目（内存+磁盘）。
    ///
    /// - Parameter completion: 清理完成后在主线程回调。
    public func ba_cleanExpired(completion: (() -> Void)? = nil) {
        // 仅清理过期项，避免误删未过期的有效内存缓存（此前误用 ba_clear() 会全量清空）。
        memoryCache.ba_removeExpired()
        diskCache.ba_cleanExpired(completion: completion)
    }
}
