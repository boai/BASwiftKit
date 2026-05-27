//
//  BAHMAC.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
import CommonCrypto

/// HMAC 签名工具。
///
/// HMAC 是带密钥的消息认证码，适合接口签名、Webhook 验签等场景。
/// 新接口通常推荐使用 HMAC-SHA256。
public enum BAHMAC {
    /// HMAC 算法。
    public enum Algorithm {
        /// HMAC-MD5，仅建议兼容旧接口。
        case md5
        /// HMAC-SHA1，仅建议兼容旧接口。
        case sha1
        /// HMAC-SHA224。
        case sha224
        /// HMAC-SHA256，推荐用于接口签名。
        case sha256
        /// HMAC-SHA384。
        case sha384
        /// HMAC-SHA512。
        case sha512

        var algorithm: CCHmacAlgorithm {
            switch self {
            case .md5: return CCHmacAlgorithm(kCCHmacAlgMD5)
            case .sha1: return CCHmacAlgorithm(kCCHmacAlgSHA1)
            case .sha224: return CCHmacAlgorithm(kCCHmacAlgSHA224)
            case .sha256: return CCHmacAlgorithm(kCCHmacAlgSHA256)
            case .sha384: return CCHmacAlgorithm(kCCHmacAlgSHA384)
            case .sha512: return CCHmacAlgorithm(kCCHmacAlgSHA512)
            }
        }

        var length: Int {
            switch self {
            case .md5: return Int(CC_MD5_DIGEST_LENGTH)
            case .sha1: return Int(CC_SHA1_DIGEST_LENGTH)
            case .sha224: return Int(CC_SHA224_DIGEST_LENGTH)
            case .sha256: return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha384: return Int(CC_SHA384_DIGEST_LENGTH)
            case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }
    }

    /// 计算 HMAC 数据。
    ///
    /// - Parameters:
    ///   - data: 原始数据。
    ///   - key: 签名密钥。
    ///   - algorithm: HMAC 算法，默认 `.sha256`。
    /// - Returns: HMAC 二进制数据。
    public static func sign(_ data: Data, key: Data, algorithm: Algorithm = .sha256) -> Data {
        var result = [UInt8](repeating: 0, count: algorithm.length)
        data.withUnsafeBytes { dataBuffer in
            key.withUnsafeBytes { keyBuffer in
                CCHmac(algorithm.algorithm,
                       keyBuffer.baseAddress,
                       keyBuffer.count,
                       dataBuffer.baseAddress,
                       dataBuffer.count,
                       &result)
            }
        }
        return Data(result)
    }

    /// 计算小写十六进制 HMAC 字符串。
    ///
    /// - Parameters:
    ///   - data: 原始数据。
    ///   - key: 签名密钥。
    ///   - algorithm: HMAC 算法，默认 `.sha256`。
    /// - Returns: 小写十六进制 HMAC 字符串。
    public static func hexString(_ data: Data, key: Data, algorithm: Algorithm = .sha256) -> String {
        sign(data, key: key, algorithm: algorithm).ba_hexString.lowercased()
    }
}
