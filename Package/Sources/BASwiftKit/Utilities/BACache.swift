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

    /// 默认要统计 / 清理的目录列表
    public static var ba_defaultDirectories: [URL] {
        var urls: [URL] = []
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            urls.append(caches)
        }
        urls.append(URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
        return urls
    }

    /// 计算指定目录的总占用字节数（递归）
    public static func ba_size(of directories: [URL] = ba_defaultDirectories) -> Int64 {
        var total: Int64 = 0
        let fm = FileManager.default
        for dir in directories {
            guard let enumerator = fm.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey],
                options: [],
                errorHandler: nil
            ) else { continue }
            for case let url as URL in enumerator {
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey])
                guard values?.isRegularFile == true else { continue }
                let size = values?.totalFileAllocatedSize ?? values?.fileSize ?? 0
                total += Int64(size)
            }
        }
        return total
    }

    /// 异步统计缓存大小，结果回到主线程
    public static func ba_sizeAsync(directories: [URL] = ba_defaultDirectories,
                                    completion: @escaping (Int64) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let bytes = ba_size(of: directories)
            DispatchQueue.main.async { completion(bytes) }
        }
    }

    /// 清理指定目录（默认 Caches + tmp）。返回是否全部成功。
    @discardableResult
    public static func ba_clear(directories: [URL] = ba_defaultDirectories) -> Bool {
        let fm = FileManager.default
        var ok = true
        for dir in directories {
            guard let items = try? fm.contentsOfDirectory(at: dir,
                                                          includingPropertiesForKeys: nil,
                                                          options: []) else {
                ok = false
                continue
            }
            for item in items {
                do { try fm.removeItem(at: item) } catch { ok = false }
            }
        }
        return ok
    }

    /// 异步清理，回调在主线程
    public static func ba_clearAsync(directories: [URL] = ba_defaultDirectories,
                                     completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let ok = ba_clear(directories: directories)
            DispatchQueue.main.async { completion(ok) }
        }
    }
}
