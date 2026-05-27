//
//  BABaseModel.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// 可缓存基础模型。
///
/// 接口 JSON 转成业务模型后，让模型继承 `BABaseModel` 并遵循 `Codable`，即可手动调用
/// `ba_saveCache()`、`ba_updateCache()`、`ba_removeCache()` 完成模型级缓存。
///
/// ```swift
/// final class UserModel: BABaseModel, Codable {
///     var id: Int = 0
///     var name: String = ""
/// }
///
/// let user = try jsonData.ba_decode(UserModel.self)
/// user.ba_saveCache()
/// let cached = UserModel.ba_cache()
/// ```
open class BABaseModel {

    /// 创建基础模型。
    public init() {}

    /// 当前模型类型默认缓存 key。
    ///
    /// 默认使用模块名 + 类型名，避免不同模块里同名模型互相覆盖。
    /// 如需按用户 ID、接口参数等维度区分缓存，可调用带 `key` 参数的方法。
    open class var ba_defaultCacheKey: String {
        String(reflecting: self)
    }

    /// 当前模型实例默认缓存 key。
    open var ba_cacheKey: String {
        Self.ba_defaultCacheKey
    }
}

public extension BABaseModel {

    /// 保存当前模型到缓存。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用 `ba_cacheKey`。
    ///   - expiry: 过期时间，默认永不过期。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`，即内存 + 磁盘混合缓存。
    /// - Returns: 模型遵循 `Encodable` 且写入成功返回 `true`，否则返回 `false`。
    @discardableResult
    func ba_saveCache(key: String? = nil,
                      expiry: Date = .distantFuture,
                      cache: BACacheManager = .default) -> Bool {
        guard let encodable = self as? Encodable,
              let data = try? JSONEncoder().encode(BABaseModelEncodableBox(encodable)) else {
            return false
        }
        cache.ba_set(data, forKey: key ?? ba_cacheKey, expiry: expiry)
        return true
    }

    /// 更新当前模型缓存。
    ///
    /// 对缓存系统来说，更新等价于用同一个 key 覆盖写入新模型；方法单独提供是为了业务语义更清晰。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用 `ba_cacheKey`。
    ///   - expiry: 过期时间，默认永不过期。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`。
    /// - Returns: 模型遵循 `Encodable` 且写入成功返回 `true`，否则返回 `false`。
    @discardableResult
    func ba_updateCache(key: String? = nil,
                        expiry: Date = .distantFuture,
                        cache: BACacheManager = .default) -> Bool {
        ba_saveCache(key: key, expiry: expiry, cache: cache)
    }

    /// 删除当前模型对应的缓存。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用 `ba_cacheKey`。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`。
    func ba_removeCache(key: String? = nil, cache: BACacheManager = .default) {
        cache.ba_remove(forKey: key ?? ba_cacheKey)
    }

    /// 读取当前模型类型的默认缓存。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用当前类型的 `ba_defaultCacheKey`。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`。
    /// - Returns: 缓存存在且未过期、解码成功时返回模型，否则返回 `nil`。
    static func ba_cache(key: String? = nil, cache: BACacheManager = .default) -> Self? {
        guard let data = cache.ba_data(forKey: key ?? ba_defaultCacheKey) else { return nil }
        return BABaseModelDecoder.decode(Self.self, from: data)
    }

    /// 判断当前模型类型是否存在有效缓存。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用当前类型的 `ba_defaultCacheKey`。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`。
    /// - Returns: 缓存存在且未过期返回 `true`。
    static func ba_hasCache(key: String? = nil, cache: BACacheManager = .default) -> Bool {
        cache.ba_contains(forKey: key ?? ba_defaultCacheKey)
    }

    /// 删除当前模型类型的缓存。
    ///
    /// - Parameters:
    ///   - key: 缓存 key；传 `nil` 时使用当前类型的 `ba_defaultCacheKey`。
    ///   - cache: 缓存管理器，默认 `BACacheManager.default`。
    static func ba_removeCache(key: String? = nil, cache: BACacheManager = .default) {
        cache.ba_remove(forKey: key ?? ba_defaultCacheKey)
    }
}

private enum BABaseModelDecoder {
    static func decode<T>(_ type: T.Type, from data: Data) -> T? {
        guard let decodableType = type as? Decodable.Type,
              let decoded = try? JSONDecoder().decode(decodableType, from: data) else {
            return nil
        }
        return decoded as? T
    }
}

private struct BABaseModelEncodableBox: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
