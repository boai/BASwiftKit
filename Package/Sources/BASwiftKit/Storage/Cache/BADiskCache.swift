//
//  BADiskCache.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 基于文件系统的线程安全磁盘缓存。
///
/// `BADiskCache` 将缓存条目序列化为 JSON 文件存储在 `Library/Caches/com.baswiftkit.diskcache/` 下，
/// 支持过期策略、总大小限制以及 LRU 淘汰。适合持久化存储模型数据、图片、网络响应等。
///
/// ```swift
/// let cache = BADiskCache()
/// cache.ba_set(data, forKey: "user_profile")
/// if let data = cache.ba_data(forKey: "user_profile") {
///     // use data
/// }
/// ```
public final class BADiskCache {

    /// 磁盘缓存总大小限制（字节）。默认 50 MB。
    /// 当总大小超过此限制时，会按 LRU 策略淘汰最旧的条目。
    public var sizeLimit: Int64

    /// 缓存文件存储目录。
    public let cacheDirectory: URL

    private let lock = NSLock()
    private let fileManager = FileManager.default

    /// 创建磁盘缓存实例。
    ///
    /// - Parameters:
    ///   - name: 缓存目录名称，默认 `"com.baswiftkit.diskcache"`。可用于区分不同业务模块的缓存。
    ///   - sizeLimit: 总大小限制（字节），默认 50 MB。
    public init(name: String = "com.baswiftkit.diskcache", sizeLimit: Int64 = 50 * 1024 * 1024) {
        self.sizeLimit = sizeLimit
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent(name, isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// 将数据存入磁盘缓存。
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
        guard let fileData = try? JSONEncoder().encode(entry) else { return }

        lock.lock()
        defer { lock.unlock() }

        let fileURL = fileURL(forKey: key)
        do {
            // 原子写入：先写临时文件再 rename，避免写入中断留下损坏文件，
            // 否则后续读取解码失败会被静默删除，表现为缓存无故丢失（与 BAFileManager.ba_write 默认 atomic 保持一致）。
            try fileData.write(to: fileURL, options: .atomic)
            checkSizeLimit()
        } catch {
            BALogger.shared.ba_error("BADiskCache write failed: \(error)")
        }
    }

    /// 从磁盘缓存读取数据。
    ///
    /// 若条目已过期，读取时会自动删除文件并返回 `nil`。
    ///
    /// - Parameter key: 缓存标识。
    /// - Returns: 缓存的二进制数据，若不存在或已过期则返回 `nil`。
    public func ba_data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        let fileURL = fileURL(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        guard let fileData = try? Data(contentsOf: fileURL),
              var entry = try? JSONDecoder().decode(BACacheEntry.self, from: fileData) else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        if entry.isExpired {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        entry.touch()
        if let updatedData = try? JSONEncoder().encode(entry) {
            try? updatedData.write(to: fileURL)
        }

        return entry.data
    }

    /// 从磁盘缓存读取并解码为模型。
    ///
    /// - Parameters:
    ///   - key: 缓存标识。
    ///   - type: 目标模型类型。
    /// - Returns: 解码后的模型，若不存在、已过期或解码失败则返回 `nil`。
    public func ba_object<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        guard let data = ba_data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// 将模型编码后存入磁盘缓存。
    ///
    /// - Parameters:
    ///   - object: 遵循 `Codable` 的模型对象。
    ///   - key: 唯一缓存标识。
    ///   - expiry: 过期时间。默认永不过期。
    public func ba_setObject<T: Encodable>(_ object: T, forKey key: String, expiry: Date = .distantFuture) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        ba_set(data, forKey: key, expiry: expiry)
    }

    /// 删除指定 key 的缓存文件。
    ///
    /// - Parameter key: 缓存标识。
    public func ba_remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        try? fileManager.removeItem(at: fileURL(forKey: key))
    }

    /// 清空全部磁盘缓存。
    public func ba_clear() {
        lock.lock()
        defer { lock.unlock() }
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? fileManager.removeItem(at: file)
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
    public func ba_totalSize() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return _unlocked_totalSize()
    }

    /// 内部使用：不加锁地计算总大小。
    /// 仅供已经持有 `lock` 的方法调用（如 `checkSizeLimit`），避免 `NSLock` 不可重入导致的死锁。
    private func _unlocked_totalSize() -> Int64 {
        var total: Int64 = 0
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey], options: []) else { return 0 }
        for file in files {
            let values = try? file.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }

    /// 异步清理所有已过期条目。
    ///
    /// - Parameter completion: 清理完成后在主线程回调。
    public func ba_cleanExpired(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?() }
                return
            }
            self.lock.lock()
            defer { self.lock.unlock() }

            guard let files = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil, options: []) else {
                DispatchQueue.main.async { completion?() }
                return
            }

            for file in files {
                guard let data = try? Data(contentsOf: file),
                      let entry = try? JSONDecoder().decode(BACacheEntry.self, from: data),
                      entry.isExpired else { continue }
                try? self.fileManager.removeItem(at: file)
            }

            DispatchQueue.main.async { completion?() }
        }
    }

    // MARK: - Private

    private func fileURL(forKey key: String) -> URL {
        let filename = key.ba_md5
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// 检查大小限制，超出时按 LRU 淘汰最旧条目。
    /// 调用方必须已经持有 `lock`（`NSLock` 不可重入，所以这里走无锁版本的 `_unlocked_totalSize`）。
    private func checkSizeLimit() {
        var totalSize = _unlocked_totalSize()
        guard totalSize > sizeLimit else { return }

        let files = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])) ?? []
        let sortedFiles = files.compactMap { url -> (url: URL, accessTime: TimeInterval)? in
            guard let data = try? Data(contentsOf: url),
                  let entry = try? JSONDecoder().decode(BACacheEntry.self, from: data) else { return nil }
            return (url, entry.lastAccessTimestamp)
        }.sorted { $0.accessTime < $1.accessTime }

        for item in sortedFiles {
            if totalSize <= sizeLimit { break }
            let fileSize = (try? fileManager.attributesOfItem(atPath: item.url.path)[.size] as? Int64) ?? 0
            try? fileManager.removeItem(at: item.url)
            totalSize -= fileSize
        }
    }
}
