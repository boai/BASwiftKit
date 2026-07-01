//
//  BASecureDelete.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation

// MARK: - BASecureDeletePassCount

/// 安全删除覆写次数。
public enum BASecureDeletePassCount: Int, Sendable {
    /// 1 次覆写（随机数据）。
    case single = 1
    /// 3 次覆写（DoD 短版：随机 → 取反 → 随机）。
    case three = 3
    /// 7 次覆写（DoD 5220.22-M 标准：交替随机与取反）。
    case seven = 7
}

// MARK: - BASecureDeleteResult

/// 安全删除结果。
public struct BASecureDeleteResult: Sendable {
    /// 被删除的文件数量。
    public let filesDeleted: Int
    /// 被删除的目录数量。
    public let directoriesDeleted: Int
    /// 失败的文件 URL 列表。
    public let failures: [URL]
    /// 总耗时（秒）。
    public let elapsedTime: TimeInterval

    public var isSuccess: Bool { failures.isEmpty }

    public init(
        filesDeleted: Int,
        directoriesDeleted: Int,
        failures: [URL],
        elapsedTime: TimeInterval
    ) {
        self.filesDeleted = filesDeleted
        self.directoriesDeleted = directoriesDeleted
        self.failures = failures
        self.elapsedTime = elapsedTime
    }
}

// MARK: - BASecureDelete

/// 安全删除工具。通过多轮覆写确保文件数据不可恢复。
///
/// 示例：
/// ```swift
/// // 安全删除单个文件
/// let result = try BASecureDelete.shred(file: fileURL, passes: .three)
///
/// // 安全删除整个目录树
/// let result = try BASecureDelete.shred(directory: dirURL, passes: .seven)
/// ```
public enum BASecureDelete {

    /// 默认写缓冲区大小：1 MB。
    public static let defaultBufferSize = 1024 * 1024

    /// 错误类型。
    public enum BASecureDeleteError: Error, Sendable {
        /// 文件不存在或不可写。
        case fileNotWritable(URL)
        /// 写入过程中出错。
        case writeError(URL)
        /// 文件截断失败。
        case truncateError(URL)
        /// 删除文件失败。
        case deleteError(URL)
    }

    // MARK: - Public API

    /// 安全删除单个文件。
    ///
    /// 执行步骤：
    /// 1. 多轮覆写文件内容（随机数据/取反）。
    /// 2. 截断文件为 0 字节。
    /// 3. 重命名为随机名称。
    /// 4. 从文件系统删除。
    ///
    /// - Parameters:
    ///   - fileURL: 待删除的文件 URL。
    ///   - passes: 覆写次数，默认 `.single`。
    ///   - bufferSize: 写入缓冲区大小，默认 1 MB。
    /// - Throws: `BASecureDeleteError`。
    public static func shred(
        file fileURL: URL,
        passes: BASecureDeletePassCount = .single,
        bufferSize: Int = defaultBufferSize
    ) throws {
        // 验证文件存在且可写
        guard FileManager.default.fileExists(atPath: fileURL.path),
              FileManager.default.isWritableFile(atPath: fileURL.path) else {
            throw BASecureDeleteError.fileNotWritable(fileURL)
        }

        // 获取文件大小
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0

        guard let fileHandle = try? FileHandle(forUpdating: fileURL) else {
            throw BASecureDeleteError.fileNotWritable(fileURL)
        }
        defer {
            try? fileHandle.close()
        }

        // 多轮覆写
        for passIndex in 0..<passes.rawValue {
            try fileHandle.seek(toOffset: 0)

            var remaining: Int64 = fileSize
            while remaining > 0 {
                let chunkSize = Int(min(Int64(bufferSize), remaining))
                let data: Data

                // 偶数轮用随机数据，奇数轮用取反（仅在 3 次及以上时启用取反）
                if passes == .single {
                    data = generateRandomData(count: chunkSize)
                } else if passIndex % 2 == 0 {
                    data = generateRandomData(count: chunkSize)
                } else {
                    // 取反轮：先读取原始内容再取反
                    let original = try? fileHandle.read(upToCount: chunkSize)
                    if let originalData = original, originalData.count > 0 {
                        let inverted = originalData.map { ~$0 }
                        data = Data(inverted)
                    } else {
                        data = generateRandomData(count: chunkSize)
                    }
                    try fileHandle.seek(toOffset: fileHandle.offsetInFile - UInt64(chunkSize))
                }

                do {
                    try fileHandle.write(contentsOf: data)
                } catch {
                    throw BASecureDeleteError.writeError(fileURL)
                }

                remaining -= Int64(chunkSize)
            }

            // 确保写入到磁盘
            try fileHandle.synchronize()
        }

        // 截断文件为 0
        do {
            try fileHandle.truncate(atOffset: 0)
            try fileHandle.synchronize()
        } catch {
            throw BASecureDeleteError.truncateError(fileURL)
        }

        try fileHandle.close()

        // 重命名为随机名称
        let parentDir = fileURL.deletingLastPathComponent()
        let randomName = UUID().uuidString
        let tempURL = parentDir.appendingPathComponent(randomName)
        try? FileManager.default.moveItem(at: fileURL, to: tempURL)

        // 从文件系统删除
        do {
            try FileManager.default.removeItem(at: tempURL)
        } catch {
            // 如果重命名后的文件删除失败，尝试删除原路径
            try? FileManager.default.removeItem(at: fileURL)
            throw BASecureDeleteError.deleteError(fileURL)
        }
    }

    /// 安全删除整个目录树（递归）。
    ///
    /// - Parameters:
    ///   - directoryURL: 待删除的目录 URL。
    ///   - passes: 覆写次数，默认 `.single`。
    ///   - bufferSize: 写入缓冲区大小。
    ///   - progress: 进度回调（主线程），参数为 (当前文件索引, 总文件数, 当前文件 URL)。
    /// - Returns: 删除结果。
    public static func shredDirectory(
        at directoryURL: URL,
        passes: BASecureDeletePassCount = .single,
        bufferSize: Int = defaultBufferSize,
        progress: ((_ index: Int, _ total: Int, _ currentURL: URL) -> Void)? = nil
    ) throws -> BASecureDeleteResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 收集目录下所有文件
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw BASecureDeleteError.fileNotWritable(directoryURL)
        }

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            throw BASecureDeleteError.fileNotWritable(directoryURL)
        }

        // 先收集所有文件 URL，避免在遍历过程中修改文件系统导致迭代器异常
        var fileURLs: [URL] = []
        var directoryURLs: [URL] = []

        for case let itemURL as URL in enumerator {
            guard let values = try? itemURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }
            if values.isRegularFile == true {
                fileURLs.append(itemURL)
            } else if values.isDirectory == true {
                directoryURLs.append(itemURL)
            }
        }

        let totalFiles = fileURLs.count
        var filesDeleted = 0
        var failures: [URL] = []

        // 逐个安全删除文件（从叶子节点开始，因为 enumerator 已经按深度优先返回）
        for (index, fileURL) in fileURLs.enumerated() {
            do {
                try shred(file: fileURL, passes: passes, bufferSize: bufferSize)
                filesDeleted += 1
            } catch {
                failures.append(fileURL)
            }

            if let progress = progress {
                DispatchQueue.main.async {
                    progress(index + 1, totalFiles, fileURL)
                }
            }
        }

        // 删除空目录（从深到浅，directoryURLs 已经是深度优先）
        var directoriesDeleted = 0
        for dirURL in directoryURLs.reversed() {
            do {
                // 检查目录是否为空（可能因文件删除失败仍有残留）
                let contents = try? FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
                if let contents = contents, contents.isEmpty {
                    try FileManager.default.removeItem(at: dirURL)
                    directoriesDeleted += 1
                }
            } catch {
                failures.append(dirURL)
            }
        }

        // 最后删除根目录
        do {
            let rootContents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            if let rootContents = rootContents, rootContents.isEmpty {
                try FileManager.default.removeItem(at: directoryURL)
                directoriesDeleted += 1
            }
        } catch {
            failures.append(directoryURL)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return BASecureDeleteResult(
            filesDeleted: filesDeleted,
            directoriesDeleted: directoriesDeleted,
            failures: failures,
            elapsedTime: elapsed
        )
    }

    /// 异步安全删除单个文件。
    ///
    /// - Parameters:
    ///   - fileURL: 待删除的文件 URL。
    ///   - passes: 覆写次数。
    ///   - bufferSize: 写入缓冲区大小。
    ///   - completion: 完成回调（主线程）。
    public static func shredAsync(
        file fileURL: URL,
        passes: BASecureDeletePassCount = .single,
        bufferSize: Int = defaultBufferSize,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try shred(file: fileURL, passes: passes, bufferSize: bufferSize)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    /// 异步安全删除整个目录树。
    ///
    /// - Parameters:
    ///   - directoryURL: 待删除的目录 URL。
    ///   - passes: 覆写次数。
    ///   - bufferSize: 写入缓冲区大小。
    ///   - progress: 进度回调（主线程）。
    ///   - completion: 完成回调（主线程）。
    public static func shredDirectoryAsync(
        at directoryURL: URL,
        passes: BASecureDeletePassCount = .single,
        bufferSize: Int = defaultBufferSize,
        progress: ((_ index: Int, _ total: Int, _ currentURL: URL) -> Void)? = nil,
        completion: @escaping @Sendable (Result<BASecureDeleteResult, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try shredDirectory(
                    at: directoryURL,
                    passes: passes,
                    bufferSize: bufferSize,
                    progress: progress
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

    // MARK: - Private Helpers

    /// 生成指定长度的随机数据。
    private static func generateRandomData(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
}
