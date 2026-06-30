//
//  BARouteParams.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

import Foundation

// MARK: - Route Params

/// 路由参数访问包装。
///
/// 路由参数底层是 `[String: Any]`（路径参数 + Query 参数合并），其中 Query / 路径参数
/// 经 URL 解析后通常是 `String`。直接 `params["age"] as? Int` 往往拿不到值
/// （因为它其实是 `"28"` 字符串）。`BARouteParams` 提供一组带「字符串兜底转换」的类型安全取值方法，
/// 让业务层免去散落各处的 `as?` / `Int(...)` 样板代码。
///
/// ```swift
/// BARouter.shared.register("/user/detail/:userId") { params in
///     let id   = params.string("userId")        // 路径参数
///     let age  = params.int("age")              // "28" -> 28
///     let vip  = params.bool("vip")             // "true"/"1" -> true
///     let name = params.string("name", default: "匿名")
///     return UserDetailViewController(id: id, age: age, vip: vip, name: name)
/// }
/// ```
public struct BARouteParams {

    /// 原始参数字典（路径参数 + Query 参数合并）。
    public let raw: [String: Any]

    /// 用原始字典构造。
    public init(_ raw: [String: Any]) {
        self.raw = raw
    }

    /// 下标直接访问原始值。
    public subscript(key: String) -> Any? { raw[key] }

    /// 是否包含某个键。
    public func contains(_ key: String) -> Bool { raw[key] != nil }

    // MARK: - Typed Accessors

    /// 取字符串。非字符串值会通过 `String(describing:)` 兜底转换。
    /// - Parameters:
    ///   - key: 参数键。
    ///   - default: 缺省值，键不存在时返回，默认空串。
    public func string(_ key: String, default defaultValue: String = "") -> String {
        if let value = raw[key] as? String { return value }
        if let value = raw[key] { return String(describing: value) }
        return defaultValue
    }

    /// 取整数。支持从字符串（如 `"28"`）解析。
    public func int(_ key: String, default defaultValue: Int = 0) -> Int {
        if let value = raw[key] as? Int { return value }
        if let value = raw[key] as? String, let parsed = Int(value) { return parsed }
        if let value = raw[key] as? Double { return Int(value) }
        return defaultValue
    }

    /// 取浮点数。支持从字符串解析。
    public func double(_ key: String, default defaultValue: Double = 0) -> Double {
        if let value = raw[key] as? Double { return value }
        if let value = raw[key] as? Int { return Double(value) }
        if let value = raw[key] as? String, let parsed = Double(value) { return parsed }
        return defaultValue
    }

    /// 取布尔值。支持 `"true"/"false"`、`"1"/"0"`、`"yes"/"no"`（大小写不敏感）。
    public func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        if let value = raw[key] as? Bool { return value }
        if let value = raw[key] as? Int { return value != 0 }
        if let value = raw[key] as? String {
            switch value.lowercased() {
            case "true", "1", "yes", "y": return true
            case "false", "0", "no", "n": return false
            default: return defaultValue
            }
        }
        return defaultValue
    }

    /// 按指定类型取值（不做转换，仅 `as?` 桥接）。
    /// 适用于通过 `BARouteRequest.params` 直接传入的 Model / 自定义对象。
    public func value<T>(_ key: String, as type: T.Type = T.self) -> T? {
        raw[key] as? T
    }
}
