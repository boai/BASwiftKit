//
//  BAUserDefaults.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

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
    public let key: String
    public let defaultValue: Value
    public let store: UserDefaults

    public init(key: String,
                defaultValue: Value,
                store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

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
    public let key: String
    public let defaultValue: Value
    public let store: UserDefaults

    public init(key: String,
                defaultValue: Value,
                store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

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
