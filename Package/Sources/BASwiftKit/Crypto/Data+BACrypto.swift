//
//  Data+BACrypto.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension Data {
    /// MD5 摘要数据。仅建议兼容旧接口。
    var ba_md5Data: Data { BADigest.digest(self, algorithm: .md5) }
    /// SHA1 摘要数据。仅建议兼容旧接口。
    var ba_sha1Data: Data { BADigest.digest(self, algorithm: .sha1) }
    /// SHA256 摘要数据，常用于完整性校验或接口签名原文摘要。
    var ba_sha256Data: Data { BADigest.digest(self, algorithm: .sha256) }
    /// SHA512 摘要数据。
    var ba_sha512Data: Data { BADigest.digest(self, algorithm: .sha512) }

    /// MD5 十六进制摘要字符串。
    var ba_md5String: String { ba_md5Data.ba_hexString.lowercased() }
    /// SHA1 十六进制摘要字符串。
    var ba_sha1String: String { ba_sha1Data.ba_hexString.lowercased() }
    /// SHA256 十六进制摘要字符串。
    var ba_sha256String: String { ba_sha256Data.ba_hexString.lowercased() }
    /// SHA512 十六进制摘要字符串。
    var ba_sha512String: String { ba_sha512Data.ba_hexString.lowercased() }

    /// 使用指定 key 计算 HMAC。
    ///
    /// - Parameters:
    ///   - key: HMAC 密钥数据。
    ///   - algorithm: HMAC 算法，默认 `.sha256`。
    /// - Returns: HMAC 数据。
    func ba_hmacData(key: Data, algorithm: BAHMAC.Algorithm = .sha256) -> Data {
        BAHMAC.sign(self, key: key, algorithm: algorithm)
    }

    /// 使用指定 key 计算 HMAC 并返回十六进制字符串。
    ///
    /// - Parameters:
    ///   - key: HMAC 密钥数据。
    ///   - algorithm: HMAC 算法，默认 `.sha256`。
    /// - Returns: 小写十六进制 HMAC 字符串。
    func ba_hmacString(key: Data, algorithm: BAHMAC.Algorithm = .sha256) -> String {
        ba_hmacData(key: key, algorithm: algorithm).ba_hexString.lowercased()
    }

    /// AES-CBC-PKCS7 加密。
    ///
    /// - Parameters:
    ///   - key: AES 密钥，长度必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量，长度必须是 16 字节。
    /// - Returns: 密文数据。
    func ba_aesCBCEncrypted(key: Data, iv: Data) throws -> Data {
        try BAAES.cbcEncrypt(self, key: key, iv: iv)
    }

    /// AES-CBC-PKCS7 解密。
    ///
    /// - Parameters:
    ///   - key: AES 密钥，长度必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量，长度必须是 16 字节。
    /// - Returns: 明文数据。
    func ba_aesCBCDecrypted(key: Data, iv: Data) throws -> Data {
        try BAAES.cbcDecrypt(self, key: key, iv: iv)
    }
}
