//
//  BAFileScanner.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation

// MARK: - BAFileScanFilter

/// 文件扫描过滤条件，所有条件为 AND 关系。`Sendable` 以支持跨并发域传递。
public struct BAFileScanFilter: Sendable {
    /// 包含的文件扩展名（不含 `.`，如 `["jpg", "png"]`），`nil` 表示不限制。
    public let includedExtensions: Set<String>?
    /// 排除的文件扩展名（不含 `.`），`nil` 表示不排除。
    public let excludedExtensions: Set<String>?
    /// 最小文件大小（字节），`nil` 表示不限制。
    public let minFileSize: Int64?
    /// 最大文件大小（字节），`nil` 表示不限制。
    public let maxFileSize: Int64?
    /// 最早修改日期，`nil` 表示不限制。
    public let modificationDateAfter: Date?
    /// 最晚修改日期，`nil` 表示不限制。
    public let modificationDateBefore: Date?
    /// 是否包含隐藏文件（以 `.` 开头）。
    public let includeHiddenFiles: Bool
    /// 是否跳过包（.app、.bundle 等）。
    public let skipPackages: Bool
    /// 是否跳过符号链接。
    public let skipSymbolicLinks: Bool
    /// 最大扫描深度（nil 为无限深度）。
    public let maxDepth: Int?

    public init(
        includedExtensions: Set<String>? = nil,
        excludedExtensions: Set<String>? = nil,
        minFileSize: Int64? = nil,
        maxFileSize: Int64? = nil,
        modificationDateAfter: Date? = nil,
        modificationDateBefore: Date? = nil,
        includeHiddenFiles: Bool = true,
        skipPackages: Bool = true,
        skipSymbolicLinks: Bool = true,
        maxDepth: Int? = nil
    ) {
        self.includedExtensions = includedExtensions
        self.excludedExtensions = excludedExtensions
        self.minFileSize = minFileSize
        self.maxFileSize = maxFileSize
        self.modificationDateAfter = modificationDateAfter
        self.modificationDateBefore = modificationDateBefore
        self.includeHiddenFiles = includeHiddenFiles
        self.skipPackages = skipPackages
        self.skipSymbolicLinks = skipSymbolicLinks
        self.maxDepth = maxDepth
    }
}

// MARK: - BAFileScanResult

/// 单次文件扫描结果。
public struct BAFileScanResult: Sendable {
    /// 扫描到的所有匹配文件的 URL。
    public let matchedURLs: [URL]
    /// 扫描过程中跳过的文件数量（因过滤条件不匹配）。
    public let skippedCount: Int
    /// 扫描的起始目录。
    public let rootURL: URL
    /// 扫描耗时（秒）。
    public let elapsedTime: TimeInterval
    /// 总扫描的条目数（含目录和跳过项）。
    public let totalScannedCount: Int

    public init(
        matchedURLs: [URL],
        skippedCount: Int,
        rootURL: URL,
        elapsedTime: TimeInterval,
        totalScannedCount: Int
    ) {
        self.matchedURLs = matchedURLs
        self.skippedCount = skippedCount
        self.rootURL = rootURL
        self.elapsedTime = elapsedTime
        self.totalScannedCount = totalScannedCount
    }
}

// MARK: - BAFileScanner

/// 递归文件扫描器。使用 `FileManager.enumerator` 实现内存高效遍历，
/// 支持过滤条件、进度回调与取消。
///
/// 示例：
/// ```swift
/// let filter = BAFileScanFilter(
///     includedExtensions: ["swift"],
///     minFileSize: 1024,
///     skipPackages: true
/// )
/// let result = try BAFileScanner.scan(
///     at: projectURL,
///     filter: filter,
///     progress: { url, current, total in
///         print("Scanning: \(url.lastPathComponent)")
///     }
/// )
/// ```
public enum BAFileScanner {

    /// 扫描进度回调。
    /// - Parameters:
    ///   - currentURL: 当前正在处理的文件 URL。
    ///   - matchedCount: 当前已匹配的文件数。
    ///   - scannedCount: 当前已扫描的条目数（含目录与跳过项）。
    public typealias ProgressHandler = @Sendable (_ currentURL: URL, _ matchedCount: Int, _ scannedCount: Int) -> Void

    /// 错误类型。
    public enum BAFileScanError: Error, Sendable {
        /// 目录不存在或不可读。
        case directoryNotAccessible(URL)
        /// 扫描被取消。
        case cancelled
    }

    // MARK: - Public API

    /// 扫描指定目录，返回所有匹配的文件 URL。
    ///
    /// - Parameters:
    ///   - url: 扫描起始目录 URL。
    ///   - filter: 过滤条件，默认不限制。
    ///   - progress: 进度回调，在主线程上调用。
    ///   - cancellation: 取消令牌，设置 `isCancelled = true` 可停止扫描。
    /// - Throws: `BAFileScanError`。
    /// - Returns: 扫描结果。
    public static func scan(
        at url: URL,
        filter: BAFileScanFilter = BAFileScanFilter(),
        progress: ProgressHandler? = nil,
        cancellation: BAFileScannerCancellationToken? = nil
    ) throws -> BAFileScanResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 验证目录可访问
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw BAFileScanError.directoryNotAccessible(url)
        }

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isPackageKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isHiddenKey,
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: filter.skipSymbolicLinks ? [.skipsHiddenFiles] : [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            throw BAFileScanError.directoryNotAccessible(url)
        }

        var matchedURLs: [URL] = []
        var skippedCount = 0
        var totalScannedCount = 0

        for case let fileURL as URL in enumerator {
            // 检查取消
            if let token = cancellation, token.isCancelled {
                throw BAFileScanError.cancelled
            }

            totalScannedCount += 1

            // 检查深度
            if let maxDepth = filter.maxDepth, enumerator.level > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            // 获取资源值
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                skippedCount += 1
                continue
            }

            // 跳过目录（仅当它们不是包时，由 skipPackages 控制）
            if resourceValues.isDirectory == true {
                if filter.skipPackages && resourceValues.isPackage == true {
                    // 跳过整个包
                    enumerator.skipDescendants()
                    skippedCount += 1
                    continue
                }
                // 普通目录：继续递归，不加入结果
                skippedCount += 1
                continue
            }

            // 跳过符号链接
            if filter.skipSymbolicLinks && resourceValues.isSymbolicLink == true {
                skippedCount += 1
                continue
            }

            // 跳过隐藏文件
            if !filter.includeHiddenFiles && resourceValues.isHidden == true {
                skippedCount += 1
                continue
            }

            // 扩展名过滤
            if let included = filter.includedExtensions {
                let ext = fileURL.pathExtension.lowercased()
                if !included.contains(ext) {
                    skippedCount += 1
                    continue
                }
            }

            if let excluded = filter.excludedExtensions {
                let ext = fileURL.pathExtension.lowercased()
                if excluded.contains(ext) {
                    skippedCount += 1
                    continue
                }
            }

            // 文件大小过滤
            if let minSize = filter.minFileSize {
                if let fileSize = resourceValues.fileSize, Int64(fileSize) < minSize {
                    skippedCount += 1
                    continue
                }
            }

            if let maxSize = filter.maxFileSize {
                if let fileSize = resourceValues.fileSize, Int64(fileSize) > maxSize {
                    skippedCount += 1
                    continue
                }
            }

            // 日期过滤
            if let after = filter.modificationDateAfter {
                if let modDate = resourceValues.contentModificationDate, modDate < after {
                    skippedCount += 1
                    continue
                }
            }

            if let before = filter.modificationDateBefore {
                if let modDate = resourceValues.contentModificationDate, modDate > before {
                    skippedCount += 1
                    continue
                }
            }

            // 通过所有过滤
            matchedURLs.append(fileURL)

            // 进度回调（主线程）
            if let progress = progress {
                DispatchQueue.main.async {
                    progress(fileURL, matchedURLs.count, totalScannedCount)
                }
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return BAFileScanResult(
            matchedURLs: matchedURLs,
            skippedCount: skippedCount,
            rootURL: url,
            elapsedTime: elapsed,
            totalScannedCount: totalScannedCount
        )
    }

    /// 异步扫描指定目录（返回在后台线程）。
    ///
    /// - Parameters:
    ///   - url: 扫描起始目录 URL。
    ///   - filter: 过滤条件，默认不限制。
    ///   - progress: 进度回调，在主线程上调用。
    ///   - cancellation: 取消令牌。
    ///   - completion: 完成回调，在主线程上调用。
    public static func scanAsync(
        at url: URL,
        filter: BAFileScanFilter = BAFileScanFilter(),
        progress: ProgressHandler? = nil,
        cancellation: BAFileScannerCancellationToken? = nil,
        completion: @escaping @Sendable (Result<BAFileScanResult, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try scan(
                    at: url,
                    filter: filter,
                    progress: progress,
                    cancellation: cancellation
                )
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - BAFileScannerCancellationToken

/// 文件扫描取消令牌，线程安全。
public final class BAFileScannerCancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _isCancelled = false

    /// 是否已被取消。
    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }

    /// 取消扫描。
    public func cancel() {
        lock.lock()
        _isCancelled = true
        lock.unlock()
    }

    public init() {}
}
