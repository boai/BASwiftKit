//
//  BAHashComputer.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation
import CommonCrypto

// MARK: - BAHashAlgorithm

/// 文件哈希算法。
public enum BAHashAlgorithm: Sendable {
    /// MD5（16 字节），不建议用于安全场景。
    case md5
    /// SHA-256（32 字节）。
    case sha256
    /// SHA-512（64 字节）。
    case sha512
}

// MARK: - BAHashResult

/// 哈希计算结果。
public struct BAHashResult: Sendable {
    /// 原始摘要数据。
    public let digest: Data
    /// 小写十六进制字符串。
    public let hexString: String
    /// 所使用的算法。
    public let algorithm: BAHashAlgorithm
    /// 文件大小（字节）。
    public let fileSize: Int64
    /// 计算耗时（秒）。
    public let elapsedTime: TimeInterval

    public init(digest: Data, hexString: String, algorithm: BAHashAlgorithm, fileSize: Int64, elapsedTime: TimeInterval) {
        self.digest = digest
        self.hexString = hexString
        self.algorithm = algorithm
        self.fileSize = fileSize
        self.elapsedTime = elapsedTime
    }
}

// MARK: - BAHashComputer

/// 流式文件哈希计算器。使用 `InputStream` 分块读取文件，避免将大文件完全载入内存。
///
/// 示例：
/// ```swift
/// let result = try BAHashComputer.hash(file: fileURL, algorithm: .sha256)
/// print(result.hexString) // → "e3b0c44298fc1c14..."
/// ```
public enum BAHashComputer {

    /// 默认分块大小：64 KB。
    public static let defaultChunkSize = 64 * 1024

    /// 计算文件的哈希值。
    ///
    /// - Parameters:
    ///   - fileURL: 文件 URL。
    ///   - algorithm: 哈希算法。
    ///   - chunkSize: 每次从流中读取的字节数，默认 64 KB。
    /// - Throws: 文件不存在、不可读或读取过程中发生错误。
    /// - Returns: 哈希结果。
    public static func hash(
        file fileURL: URL,
        algorithm: BAHashAlgorithm,
        chunkSize: Int = defaultChunkSize
    ) throws -> BAHashResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 获取文件大小
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (fileAttributes[.size] as? NSNumber)?.int64Value ?? 0

        guard let inputStream = InputStream(url: fileURL) else {
            throw BAHashError.fileNotReadable(fileURL)
        }

        inputStream.open()
        defer { inputStream.close() }

        var buffer = [UInt8](repeating: 0, count: chunkSize)

        // 为每种算法创建上下文
        let result: Data
        switch algorithm {
        case .md5:
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: chunkSize)
                if bytesRead < 0 {
                    throw BAHashError.readError(fileURL)
                }
                if bytesRead == 0 { break }
                _ = CC_MD5_Update(&context, buffer, CC_LONG(bytesRead))
            }
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = CC_MD5_Final(&digest, &context)
            result = Data(digest)

        case .sha256:
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: chunkSize)
                if bytesRead < 0 {
                    throw BAHashError.readError(fileURL)
                }
                if bytesRead == 0 { break }
                _ = CC_SHA256_Update(&context, buffer, CC_LONG(bytesRead))
            }
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = CC_SHA256_Final(&digest, &context)
            result = Data(digest)

        case .sha512:
            var context = CC_SHA512_CTX()
            CC_SHA512_Init(&context)
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: chunkSize)
                if bytesRead < 0 {
                    throw BAHashError.readError(fileURL)
                }
                if bytesRead == 0 { break }
                _ = CC_SHA512_Update(&context, buffer, CC_LONG(bytesRead))
            }
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            _ = CC_SHA512_Final(&digest, &context)
            result = Data(digest)
        }

        let hexString = result.map { String(format: "%02x", $0) }.joined()
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return BAHashResult(
            digest: result,
            hexString: hexString,
            algorithm: algorithm,
            fileSize: fileSize,
            elapsedTime: elapsed
        )
    }

    /// 异步计算文件哈希值。
    ///
    /// - Parameters:
    ///   - fileURL: 文件 URL。
    ///   - algorithm: 哈希算法。
    ///   - chunkSize: 分块大小。
    ///   - completion: 完成回调，在主线程上调用。
    public static func hashAsync(
        file fileURL: URL,
        algorithm: BAHashAlgorithm,
        chunkSize: Int = defaultChunkSize,
        completion: @escaping @Sendable (Result<BAHashResult, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try hash(file: fileURL, algorithm: algorithm, chunkSize: chunkSize)
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

    /// 计算 Data 的哈希值（内存数据）。
    ///
    /// - Parameters:
    ///   - data: 待哈希数据。
    ///   - algorithm: 哈希算法。
    /// - Returns: 原始摘要数据。
    public static func hash(data: Data, algorithm: BAHashAlgorithm) -> Data {
        switch algorithm {
        case .md5:
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            data.withUnsafeBytes { _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &digest) }
            return Data(digest)
        case .sha256:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
            return Data(digest)
        case .sha512:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            data.withUnsafeBytes { _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &digest) }
            return Data(digest)
        }
    }

    /// 错误类型。
    public enum BAHashError: Error, Sendable {
        /// 文件不可读。
        case fileNotReadable(URL)
        /// 读取过程中出错。
        case readError(URL)
    }
}
