//
//  BACrypto.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
import CommonCrypto

/// 加密模块公共错误。
public enum BACryptoError: Error {
    /// key 长度不符合算法要求。
    case invalidKeyLength
    /// IV 长度不符合算法要求。
    case invalidIVLength
    /// CommonCrypto 操作失败。
    case cryptFailed(status: CCCryptorStatus)
    /// 字符串无法按指定编码转为 Data。
    case stringEncodingFailed
    /// 安全随机数生成失败（SecRandomCopyBytes）。
    case randomGenerationFailed
    /// 口令密钥派生（PBKDF2）失败。
    case keyDerivationFailed
    /// 密文格式不合法（头部缺失、长度不足或版本不支持）。
    case invalidCipherFormat
}

/// 加密模块兼容入口。
///
/// 新代码推荐直接使用职责更清晰的独立类型：
/// - `BADigest`：MD5/SHA 摘要
/// - `BAHMAC`：HMAC 签名
/// - `BAAES`：AES 对称加解密
///
/// `BACrypto` 保留为轻量命名空间，避免旧调用方立刻迁移。
public enum BACrypto {
    /// 摘要算法类型别名。
    public typealias DigestAlgorithm = BADigest.Algorithm
    /// HMAC 算法类型别名。
    public typealias HMACAlgorithm = BAHMAC.Algorithm
    /// 加解密错误类型别名。
    public typealias CryptoError = BACryptoError

    /// 计算数据摘要。新代码推荐使用 `BADigest.digest(_:algorithm:)`。
    public static func digest(_ data: Data, algorithm: DigestAlgorithm) -> Data {
        BADigest.digest(data, algorithm: algorithm)
    }

    /// 计算 HMAC。新代码推荐使用 `BAHMAC.sign(_:key:algorithm:)`。
    public static func hmac(_ data: Data, key: Data, algorithm: HMACAlgorithm = .sha256) -> Data {
        BAHMAC.sign(data, key: key, algorithm: algorithm)
    }

    /// AES-CBC-PKCS7 加密。新代码推荐使用 `BAAES.cbcEncrypt(_:key:iv:)`。
    public static func aesCBCEncrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        try BAAES.cbcEncrypt(data, key: key, iv: iv)
    }

    /// AES-CBC-PKCS7 解密。新代码推荐使用 `BAAES.cbcDecrypt(_:key:iv:)`。
    public static func aesCBCDecrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        try BAAES.cbcDecrypt(data, key: key, iv: iv)
    }
}
