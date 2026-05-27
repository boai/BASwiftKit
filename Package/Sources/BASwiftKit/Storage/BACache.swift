//
//  BACache.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// 缓存清理工具。
///
/// 默认管理两个目录：
/// - `Library/Caches/`（FileManager.cachesDirectory）
/// - `tmp/`（NSTemporaryDirectory()）
///
/// 用户文件（Documents）不会被动到。
public enum BACache {

    /// 默认要统计 / 清理的目录列表。
    public static var ba_defaultDirectories: [URL] {
        [BAFileManager.ba_cachesDirectory, BAFileManager.ba_temporaryDirectory]
    }

    /// 计算指定目录的总占用字节数（递归）。
    ///
    /// - Parameter directories: 要统计的目录数组，默认 Caches + tmp。
    /// - Returns: 总字节数；单个文件读取失败时会跳过该文件。
    public static func ba_size(of directories: [URL] = ba_defaultDirectories) -> Int64 {
        directories.reduce(Int64(0)) { total, directory in
            total + Int64((try? BAFileManager.ba_sizeOfItem(at: directory)) ?? 0)
        }
    }

    /// 计算默认缓存目录大小并格式化为可展示文本。
    public static var ba_formattedSize: String {
        BAFileManager.ba_formattedSize(ba_size())
    }

    /// 异步统计缓存大小，结果回到主线程。
    ///
    /// - Parameters:
    ///   - directories: 要统计的目录数组，默认 Caches + tmp。
    ///   - completion: 主线程回调，返回总字节数。
    public static func ba_sizeAsync(directories: [URL] = ba_defaultDirectories,
                                    completion: @escaping (Int64) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let bytes = ba_size(of: directories)
            DispatchQueue.main.async { completion(bytes) }
        }
    }

    /// 异步统计缓存大小并返回格式化文本，适合直接刷新 UI。
    ///
    /// - Parameters:
    ///   - directories: 要统计的目录数组，默认 Caches + tmp。
    ///   - completion: 主线程回调，返回格式化大小文本。
    public static func ba_formattedSizeAsync(directories: [URL] = ba_defaultDirectories,
                                             completion: @escaping (String) -> Void) {
        ba_sizeAsync(directories: directories) { bytes in
            completion(BAFileManager.ba_formattedSize(bytes))
        }
    }

    /// 清理指定目录（默认 Caches + tmp）。返回是否全部成功。
    ///
    /// - Parameter directories: 要清理的目录数组，默认 Caches + tmp。
    /// - Returns: 所有目录都清理成功时返回 `true`。
    @discardableResult
    public static func ba_clear(directories: [URL] = ba_defaultDirectories) -> Bool {
        let results = directories.map { directory -> Bool in
            guard let items = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
                return false
            }
            return items.reduce(true) { success, item in
                do {
                    try BAFileManager.ba_removeItem(at: item)
                    return success
                } catch {
                    return false
                }
            }
        }
        return results.allSatisfy { $0 }
    }

    /// 异步清理，回调在主线程。
    ///
    /// - Parameters:
    ///   - directories: 要清理的目录数组，默认 Caches + tmp。
    ///   - completion: 主线程回调，返回是否全部成功。
    public static func ba_clearAsync(directories: [URL] = ba_defaultDirectories,
                                     completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let ok = ba_clear(directories: directories)
            DispatchQueue.main.async { completion(ok) }
        }
    }

    /// 异步清理并在回调中返回清理后的缓存大小。
    ///
    /// - Parameters:
    ///   - directories: 要清理的目录数组，默认 Caches + tmp。
    ///   - completion: 主线程回调，返回 `success` 和清理后的字节数。
    public static func ba_clearAsync(directories: [URL] = ba_defaultDirectories,
                                     completion: @escaping (_ success: Bool, _ remainingBytes: Int64) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let ok = ba_clear(directories: directories)
            let bytes = ba_size(of: directories)
            DispatchQueue.main.async { completion(ok, bytes) }
        }
    }
}
