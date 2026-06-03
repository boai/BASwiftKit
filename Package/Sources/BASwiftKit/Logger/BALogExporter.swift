//
//  BALogExporter.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

import Foundation
import CommonCrypto

// MARK: - BALogExporter

/// 日志导出器。
///
/// 从数据库按日期查询日志，格式化为 TXT 文本，使用 AES-256-CBC 加密后写入文件。
///
/// ```swift
/// let exporter = BALogExporter()
/// let url = try exporter.export(date: "2026-06-02", password: "mypassword")
/// // 分享 url
/// ```
public final class BALogExporter {

    /// 数据库实例。
    public let database: BALogSQLiteStore

    // MARK: - Init

    /// 创建导出器。
    ///
    /// - Parameter database: 日志数据库，默认使用 `BALogSQLiteStore.shared`。
    public init(database: BALogSQLiteStore = .shared) {
        self.database = database
    }

    // MARK: - Export

    /// 导出指定日期的日志为加密 TXT 文件。
    ///
    /// - Parameters:
    ///   - date: 日期字符串（"yyyy-MM-dd" 格式）。
    ///   - password: 加密密码（不能为空）。
    ///   - outputDir: 输出目录，默认为临时目录。
    /// - Returns: 加密后的文件 URL（扩展名为 `.txt.enc`）。
    /// - Throws: 数据库读取失败、加密失败或密码为空时抛出。
    public func export(date: String, password: String, outputDir: URL? = nil) throws -> URL {
        guard !password.isEmpty else { throw BALogExportError.emptyPassword }

        let entries = database.fetch(dateString: date)
        let text = formatAsText(entries: entries, date: date)

        guard let textData = text.data(using: .utf8) else {
            throw BALogExportError.encodingFailed
        }

        let encrypted = try encrypt(data: textData, password: password)

        let dir = outputDir ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = "logs_\(date).txt.enc"
        let fileURL = dir.appendingPathComponent(fileName)
        try encrypted.write(to: fileURL)

        return fileURL
    }

    /// 导出日期范围内的日志为加密 TXT 文件。
    public func export(from startDate: String, to endDate: String, password: String, outputDir: URL? = nil) throws -> URL {
        guard !password.isEmpty else { throw BALogExportError.emptyPassword }

        let entries = database.fetch(from: startDate, to: endDate)
        let text = formatAsText(entries: entries, date: "\(startDate) ~ \(endDate)")

        guard let textData = text.data(using: .utf8) else {
            throw BALogExportError.encodingFailed
        }

        let encrypted = try encrypt(data: textData, password: password)

        let dir = outputDir ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = "logs_\(startDate)_\(endDate).txt.enc"
        let fileURL = dir.appendingPathComponent(fileName)
        try encrypted.write(to: fileURL)

        return fileURL
    }

    /// 解密已导出的加密日志文件。
    ///
    /// - Parameters:
    ///   - fileURL: 加密文件的 URL。
    ///   - password: 解密密码。
    /// - Returns: 解密后的文本内容。
    /// - Throws: 文件读取失败、解密失败或密码错误时抛出。
    public static func decrypt(fileURL: URL, password: String) throws -> String {
        let encrypted = try Data(contentsOf: fileURL)
        return try decrypt(data: encrypted, password: password)
    }

    // MARK: - Private: Format

    private func formatAsText(entries: [BALogEntry], date: String) -> String {
        var output = ""
        output += "========================================\n"
        output += "  BASwiftKit 日志导出\n"
        output += "  日期: \(date)\n"
        output += "  导出时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n"
        output += "  日志总数: \(entries.count)\n"
        output += "========================================\n\n"

        if entries.isEmpty {
            output += "（无日志记录）\n"
        } else {
            for entry in entries {
                output += "[\(entry.timeString)] [\(entry.level.displayName)]\n"
                output += "  \(entry.message)\n"
                if let ctx = entry.context, let ctxData = ctx.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: ctxData) as? [String: Any] {
                    let info = dict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    output += "  → \(info)\n"
                }
                output += "\n"
            }
        }

        output += "========================================\n"
        output += "  BASwiftKit - 日志导出完毕\n"
        output += "========================================\n"
        return output
    }

    // MARK: - Private: Encryption

    private func encrypt(data: Data, password: String) throws -> Data {
        let key = Self.deriveKey(from: password)
        var iv = Data(count: kCCBlockSizeAES128)
        _ = iv.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ptr.baseAddress!)
        }

        let encrypted = try data.ba_aesCBCEncrypted(key: key, iv: iv)

        // 头部写入 IV（16 字节），方便解密时提取
        var result = Data()
        result.append(iv)
        result.append(encrypted)
        return result
    }

    /// 解密函数：从文件数据中提取 IV 并解密。
    public static func decrypt(data: Data, password: String) throws -> String {
        guard data.count > kCCBlockSizeAES128 else {
            throw BALogExportError.decryptFailed
        }
        let iv = data.prefix(kCCBlockSizeAES128)
        let encrypted = data.suffix(from: kCCBlockSizeAES128)
        let key = Self.deriveKey(from: password)
        let decrypted = try encrypted.ba_aesCBCDecrypted(key: key, iv: iv)
        guard let text = String(data: decrypted, encoding: .utf8) else {
            throw BALogExportError.decryptFailed
        }
        return text
    }

    private static func deriveKey(from password: String) -> Data {
        guard let passwordData = password.data(using: .utf8) else {
            return Data(repeating: 0, count: kCCKeySizeAES256)
        }
        // SHA256 → 32 字节 AES-256 密钥
        var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = hash.withUnsafeMutableBytes { hashPtr in
            passwordData.withUnsafeBytes { passPtr in
                CC_SHA256(passPtr.baseAddress, CC_LONG(passwordData.count), hashPtr.baseAddress)
            }
        }
        return hash
    }
}

// MARK: - BALogExportError

/// 日志导出错误。
public enum BALogExportError: Error, LocalizedError {
    /// 密码为空。
    case emptyPassword
    /// 文本编码失败。
    case encodingFailed
    /// 加密失败。
    case encryptFailed
    /// 解密失败（密码错误或数据损坏）。
    case decryptFailed

    public var errorDescription: String? {
        switch self {
        case .emptyPassword: return "密码不能为空"
        case .encodingFailed: return "文本编码失败"
        case .encryptFailed: return "加密失败"
        case .decryptFailed: return "解密失败，密码错误或文件已损坏"
        }
    }
}
