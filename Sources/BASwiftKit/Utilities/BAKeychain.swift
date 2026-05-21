//
//  BAKeychain.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation
import Security

/// 轻量 Keychain 封装：仅支持 String / Data 值。
public enum BAKeychain {

    /// 存储字符串
    @discardableResult
    public static func ba_set(_ value: String, forKey key: String, service: String = defaultService) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return ba_set(data, forKey: key, service: service)
    }

    /// 存储二进制
    @discardableResult
    public static func ba_set(_ data: Data, forKey key: String, service: String = defaultService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 读取字符串
    public static func ba_string(forKey key: String, service: String = defaultService) -> String? {
        guard let data = ba_data(forKey: key, service: service) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 读取二进制
    public static func ba_data(forKey key: String, service: String = defaultService) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// 删除
    @discardableResult
    public static func ba_remove(forKey key: String, service: String = defaultService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    /// 默认 service 名称（沿用 Bundle Identifier）
    public static var defaultService: String {
        Bundle.main.bundleIdentifier ?? "com.baswiftkit.keychain"
    }
}
