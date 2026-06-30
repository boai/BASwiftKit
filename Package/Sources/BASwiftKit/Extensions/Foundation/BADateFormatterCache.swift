//
//  BADateFormatterCache.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

import Foundation

/// 内部共享的 `DateFormatter` 缓存（性能优化）。
///
/// `DateFormatter` 创建并配置一次成本较高（涉及 ICU 解析），而日期格式化/解析常被高频调用。
/// 这里按「格式串 + localeIdentifier + timeZoneIdentifier」为 key 缓存并复用已配置好的实例。
///
/// 线程安全说明：`DateFormatter` 在 iOS 7+ **配置完成后只读使用是线程安全的**，因此可作为共享实例。
/// 仅缓存字典的读写需要保护，用一把 `NSLock` 串行化访问即可。
///
/// 用法（仅库内部使用）：
/// ```swift
/// let f = BADateFormatterCache.formatter(format: "yyyy-MM-dd", locale: .current, timeZone: .current)
/// let text = f.string(from: Date())
/// ```
/// - Important: 取回的格式化器为共享实例，调用方**不得**再修改其属性（如 dateFormat / locale），
///   只能用于 `string(from:)` / `date(from:)` 等只读操作，否则会影响其它复用方。
enum BADateFormatterCache {

    /// 已配置好的格式化器缓存。
    private static var cache: [String: DateFormatter] = [:]
    /// 保护 `cache` 读写的锁。
    private static let lock = NSLock()

    /// 取回（或创建并缓存）指定「格式 + locale + 时区」对应的格式化器。
    ///
    /// - Parameters:
    ///   - format: 日期格式串（如 `"yyyy-MM-dd HH:mm:ss"`）。
    ///   - locale: 地区设置。机器可读固定格式应传 `Locale(identifier: "en_US_POSIX")`；
    ///     面向展示的本地化格式传 `.current`。
    ///   - timeZone: 时区，默认 `.current`。
    /// - Returns: 配置完成、可复用的只读格式化器。
    static func formatter(format: String,
                          locale: Locale,
                          timeZone: TimeZone = .current) -> DateFormatter {
        // key 需包含三要素，任一不同都应得到独立实例。
        let key = "\(format)|\(locale.identifier)|\(timeZone.identifier)"

        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format

        lock.lock()
        cache[key] = formatter
        lock.unlock()
        return formatter
    }

    /// 机器可读固定格式专用的 POSIX 地区，避免非公历/12 小时制等区域导致解析或序列化异常。
    static let posixLocale = Locale(identifier: "en_US_POSIX")
}
