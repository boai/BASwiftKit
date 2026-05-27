//
//  BADigest.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
import CommonCrypto

/// 摘要工具，负责 MD5/SHA 系列哈希。
///
/// 摘要是不可逆的固定长度结果，适合做完整性校验、签名前原文摘要、旧接口兼容等。
/// MD5/SHA1 已不适合安全场景，新接口优先使用 SHA256 及以上算法。
public enum BADigest {
    /// 摘要算法。
    public enum Algorithm {
        /// MD5，16 字节摘要。仅建议兼容旧接口。
        case md5
        /// SHA1，20 字节摘要。仅建议兼容旧接口。
        case sha1
        /// SHA224，28 字节摘要。
        case sha224
        /// SHA256，32 字节摘要，常用于完整性校验。
        case sha256
        /// SHA384，48 字节摘要。
        case sha384
        /// SHA512，64 字节摘要。
        case sha512

        var length: Int32 {
            switch self {
            case .md5: return CC_MD5_DIGEST_LENGTH
            case .sha1: return CC_SHA1_DIGEST_LENGTH
            case .sha224: return CC_SHA224_DIGEST_LENGTH
            case .sha256: return CC_SHA256_DIGEST_LENGTH
            case .sha384: return CC_SHA384_DIGEST_LENGTH
            case .sha512: return CC_SHA512_DIGEST_LENGTH
            }
        }
    }

    /// 计算二进制摘要。
    ///
    /// - Parameters:
    ///   - data: 原始数据。
    ///   - algorithm: 摘要算法。
    /// - Returns: 摘要数据。
    public static func digest(_ data: Data, algorithm: Algorithm) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(algorithm.length))
        data.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress
            let count = CC_LONG(buffer.count)
            switch algorithm {
            case .md5:
                _ = CC_MD5(baseAddress, count, &digest)
            case .sha1:
                _ = CC_SHA1(baseAddress, count, &digest)
            case .sha224:
                _ = CC_SHA224(baseAddress, count, &digest)
            case .sha256:
                _ = CC_SHA256(baseAddress, count, &digest)
            case .sha384:
                _ = CC_SHA384(baseAddress, count, &digest)
            case .sha512:
                _ = CC_SHA512(baseAddress, count, &digest)
            }
        }
        return Data(digest)
    }

    /// 计算小写十六进制摘要字符串。
    ///
    /// - Parameters:
    ///   - data: 原始数据。
    ///   - algorithm: 摘要算法。
    /// - Returns: 小写十六进制摘要。
    public static func hexString(_ data: Data, algorithm: Algorithm) -> String {
        digest(data, algorithm: algorithm).ba_hexString.lowercased()
    }
}
