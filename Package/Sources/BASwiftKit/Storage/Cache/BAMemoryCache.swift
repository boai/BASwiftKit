//
//  BAMemoryCache.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// 基于 `NSCache` 的线程安全内存缓存。
///
/// `BAMemoryCache` 包装了 `NSCache` 并增加了过期时间管理，适合存储临时数据、图片、模型等。
/// 当应用收到内存警告时，会自动清空全部缓存。
///
/// ```swift
/// let cache = BAMemoryCache()
/// cache.ba_set(data, forKey: "avatar")
/// if let data = cache.ba_data(forKey: "avatar") {
///     // use data
/// }
/// ```
public final class BAMemoryCache {

    /// 缓存总成本限制。超过此值时 `NSCache` 会自动淘汰条目。
    public var costLimit: Int {
        get { cache.totalCostLimit }
        set { cache.totalCostLimit = newValue }
    }

    /// 缓存条目数量限制。超过此值时 `NSCache` 会自动淘汰条目。
    public var countLimit: Int {
        get { cache.countLimit }
        set { cache.countLimit = newValue }
    }

    private let cache = NSCache<NSString, CacheWrapper>()
    private let lock = NSLock()

    /// 创建内存缓存实例。
    ///
    /// - Parameters:
    ///   - costLimit: 总成本限制，默认无限制（`0`）。
    ///   - countLimit: 条目数量限制，默认无限制（`0`）。
    public init(costLimit: Int = 0, countLimit: Int = 0) {
        self.cache.totalCostLimit = costLimit
        self.cache.countLimit = countLimit
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    /// 将数据存入内存缓存。
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
        let entry = BACacheEntry(key: key, data: data, expiry: expiry, cost: cost)
        let wrapper = CacheWrapper(entry: entry)
        lock.lock()
        cache.setObject(wrapper, forKey: key as NSString, cost: entry.cost)
        lock.unlock()
    }

    /// 从内存缓存读取数据。
    ///
    /// 若条目已过期，读取时会自动删除并返回 `nil`。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的二进制数据，若不存在或已过期则返回 `nil`。
    public func ba_data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        guard let wrapper = cache.object(forKey: key as NSString) else { return nil }
        var entry = wrapper.entry
        if entry.isExpired {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        entry.touch()
        wrapper.entry = entry
        return entry.data
    }

    /// 从内存缓存读取并解码为模型。
    ///
    /// - Parameters:
    ///   - key: 缓存标识。
    ///   - type: 目标模型类型。
    /// - Returns: 解码后的模型，若不存在、已过期或解码失败则返回 `nil`。
    public func ba_object<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        guard let data = ba_data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// 将模型编码后存入内存缓存。
    ///
    /// - Parameters:
    ///   - object: 遵循 `Codable` 的模型对象。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setObject<T: Encodable>(_ object: T, forKey key: String, expiry: Date = .distantFuture) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        ba_set(data, forKey: key, expiry: expiry)
    }

    /// 删除指定 key 的缓存。
    ///
    /// - Parameter key: 缓存标识。
    public func ba_remove(forKey key: String) {
        lock.lock()
        cache.removeObject(forKey: key as NSString)
        lock.unlock()
    }

    /// 清空全部内存缓存。
    public func ba_clear() {
        lock.lock()
        cache.removeAllObjects()
        lock.unlock()
    }

    /// 判断是否包含指定 key 的缓存（且未过期）。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 若存在且未过期返回 `true`。
    public func ba_contains(forKey key: String) -> Bool {
        ba_data(forKey: key) != nil
    }

    // MARK: - Private

    @objc private func didReceiveMemoryWarning() {
        ba_clear()
    }
}

// MARK: - CacheWrapper

/// `NSCache` 要求存储对象继承自 `NSObject`，因此用包装类包裹 `BACacheEntry`。
private final class CacheWrapper: NSObject {
    var entry: BACacheEntry
    init(entry: BACacheEntry) {
        self.entry = entry
    }
}
