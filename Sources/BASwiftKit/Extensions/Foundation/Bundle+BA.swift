//
//  Bundle+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

public extension Bundle {

    // MARK: - App 元数据（与 BADeviceInfo 等价的便捷访问）

    var ba_appName: String {
        (infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (infoDictionary?["CFBundleName"] as? String)
            ?? ""
    }

    var ba_appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var ba_buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    var ba_bundleId: String { bundleIdentifier ?? "" }

    // MARK: - Info.plist 任意 key

    /// 读取 Info.plist 中的任意 key
    func ba_infoValue<T>(forKey key: String) -> T? {
        infoDictionary?[key] as? T
    }

    // MARK: - 文件查找

    /// 查找资源文件 URL
    func ba_resourceURL(named name: String, ext: String?) -> URL? {
        url(forResource: name, withExtension: ext)
    }

    /// 把资源文件读为 Data
    func ba_resourceData(named name: String, ext: String?) -> Data? {
        guard let url = ba_resourceURL(named: name, ext: ext) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// 解析 JSON 资源文件（数组 / 字典皆可）
    func ba_resourceJSON(named name: String, ext: String = "json") -> Any? {
        guard let data = ba_resourceData(named: name, ext: ext) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}
