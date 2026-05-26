//
//  BACacheEntry.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 缓存条目元数据模型，用于磁盘持久化。
///
/// 每个缓存条目包含原始数据、过期时间、存储成本以及最后访问时间（用于 LRU 淘汰）。
/// 支持 `Codable` 协议，可直接序列化为 JSON 存储到磁盘。
public struct BACacheEntry: Codable {

    /// 缓存键，唯一标识该条目。
    public let key: String

    /// 缓存的原始二进制数据。
    public var data: Data

    /// 过期时间戳（自 1970 起的秒数）。
    /// 读取时若当前时间超过此值，条目视为过期并会被清理。
    public var expiryTimestamp: TimeInterval

    /// 存储成本，用于内存缓存的 `NSCache` 成本计算。
    public var cost: Int

    /// 最后访问时间戳（自 1970 起的秒数），用于磁盘缓存的 LRU 淘汰策略。
    public var lastAccessTimestamp: TimeInterval

    /// 创建一条缓存条目。
    ///
    /// - Parameters:
    ///   - key: 唯一缓存标识。
    ///   - data: 要存储的二进制数据。
    ///   - expiry: 过期时间。默认永不过期（`.distantFuture`）。
    ///   - cost: 存储成本，默认使用 `data.count`。
    public init(key: String,
                data: Data,
                expiry: Date = .distantFuture,
                cost: Int? = nil) {
        self.key = key
        self.data = data
        self.expiryTimestamp = expiry.timeIntervalSince1970
        self.cost = cost ?? data.count
        self.lastAccessTimestamp = Date().timeIntervalSince1970
    }

    /// 该条目是否已过期。
    public var isExpired: Bool {
        Date().timeIntervalSince1970 > expiryTimestamp
    }

    /// 更新最后访问时间为当前时间（命中缓存时调用）。
    public mutating func touch() {
        lastAccessTimestamp = Date().timeIntervalSince1970
    }
}
