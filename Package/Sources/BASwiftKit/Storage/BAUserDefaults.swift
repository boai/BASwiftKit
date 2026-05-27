//
//  BAUserDefaults.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// UserDefaults 便捷读写工具。
public enum BAUserDefaults {
    /// 读取基础类型值。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - defaultValue: key 不存在或类型不匹配时返回的默认值。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    /// - Returns: 读取到的值或默认值。
    public static func ba_value<T>(forKey key: String,
                                   default defaultValue: T,
                                   store: UserDefaults = .standard) -> T {
        store.object(forKey: key) as? T ?? defaultValue
    }

    /// 写入基础类型值；传入 nil 时删除对应 key。
    ///
    /// - Parameters:
    ///   - value: 要保存的值，传 nil 删除 key。
    ///   - key: UserDefaults 存储 key。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    public static func ba_set<T>(_ value: T?, forKey key: String, store: UserDefaults = .standard) {
        if let value {
            store.set(value, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
    }

    /// 判断指定 key 是否存在。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - store: 实际读取的 UserDefaults 实例，默认 `.standard`。
    /// - Returns: key 已存在返回 `true`。
    public static func ba_contains(_ key: String, store: UserDefaults = .standard) -> Bool {
        store.object(forKey: key) != nil
    }

    /// 删除指定 key。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - store: 实际操作的 UserDefaults 实例，默认 `.standard`。
    public static func ba_remove(_ key: String, store: UserDefaults = .standard) {
        store.removeObject(forKey: key)
    }

    /// 读取 Codable 值。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - type: 目标类型。
    ///   - defaultValue: key 不存在或解码失败时返回的默认值。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    ///   - decoder: JSON 解码器，默认 `JSONDecoder()`。
    /// - Returns: 解码后的值或默认值。
    public static func ba_codable<T: Decodable>(forKey key: String,
                                                type: T.Type,
                                                default defaultValue: T,
                                                store: UserDefaults = .standard,
                                                decoder: JSONDecoder = JSONDecoder()) -> T {
        guard let data = store.data(forKey: key),
              let value = try? decoder.decode(type, from: data) else {
            return defaultValue
        }
        return value
    }

    /// 写入 Codable 值；传入 nil 时删除对应 key。
    ///
    /// - Parameters:
    ///   - value: 要保存的 Codable 值，传 nil 删除 key。
    ///   - key: UserDefaults 存储 key。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    ///   - encoder: JSON 编码器，默认 `JSONEncoder()`。
    public static func ba_setCodable<T: Encodable>(_ value: T?,
                                                   forKey key: String,
                                                   store: UserDefaults = .standard,
                                                   encoder: JSONEncoder = JSONEncoder()) {
        guard let value else {
            store.removeObject(forKey: key)
            return
        }
        if let data = try? encoder.encode(value) {
            store.set(data, forKey: key)
        }
    }
}

/// UserDefaults 封装：通过 property wrapper 提供类型安全访问。
///
/// ```swift
/// enum AppPrefs {
///     @BAUserDefault(key: "is_first_launch", defaultValue: true)
///     static var isFirstLaunch: Bool
/// }
/// ```
@propertyWrapper
public struct BAUserDefault<Value> {
    /// UserDefaults 存储 key。
    public let key: String
    /// key 不存在或类型不匹配时返回的默认值。
    public let defaultValue: Value
    /// 实际读写的 UserDefaults 实例，默认 `.standard`。
    public let store: UserDefaults

    /// 创建基础类型 UserDefaults 包装器。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - defaultValue: key 不存在或类型不匹配时返回的默认值。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    public init(key: String,
                defaultValue: Value,
                store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    /// 被包装的值。设置为 `nil` 的 Optional 值时会删除对应 key。
    public var wrappedValue: Value {
        get { store.object(forKey: key) as? Value ?? defaultValue }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                store.removeObject(forKey: key)
            } else {
                store.set(newValue, forKey: key)
            }
        }
    }
}

/// 为 Codable 类型提供独立的 wrapper，存为 JSON。
@propertyWrapper
public struct BAUserDefaultCodable<Value: Codable> {
    /// UserDefaults 存储 key。
    public let key: String
    /// key 不存在、数据缺失或 JSON 解码失败时返回的默认值。
    public let defaultValue: Value
    /// 实际读写的 UserDefaults 实例，默认 `.standard`。
    public let store: UserDefaults

    /// 创建 Codable 类型 UserDefaults 包装器。
    ///
    /// - Parameters:
    ///   - key: UserDefaults 存储 key。
    ///   - defaultValue: key 不存在、数据缺失或 JSON 解码失败时返回的默认值。
    ///   - store: 实际读写的 UserDefaults 实例，默认 `.standard`。
    public init(key: String,
                defaultValue: Value,
                store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    /// 被包装的 Codable 值。设置为 `nil` 的 Optional 值时会删除对应 key。
    public var wrappedValue: Value {
        get {
            guard let data = store.data(forKey: key),
                  let value = try? JSONDecoder().decode(Value.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                store.removeObject(forKey: key)
            } else if let data = try? JSONEncoder().encode(newValue) {
                store.set(data, forKey: key)
            }
        }
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
