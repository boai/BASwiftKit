//
//  String+BACrypto.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension String {
    /// SHA1 十六进制摘要字符串。仅建议兼容旧接口。
    var ba_sha1: String { ba_utf8Data.ba_sha1String }
    /// SHA256 十六进制摘要字符串，推荐用于非密钥摘要场景。
    var ba_sha256: String { ba_utf8Data.ba_sha256String }
    /// SHA512 十六进制摘要字符串。
    var ba_sha512: String { ba_utf8Data.ba_sha512String }

    /// 使用字符串 key 计算 HMAC。
    ///
    /// - Parameters:
    ///   - key: HMAC 密钥字符串，按 UTF-8 转为 Data。
    ///   - algorithm: HMAC 算法，默认 `.sha256`。
    /// - Returns: 小写十六进制 HMAC 字符串。
    func ba_hmac(key: String, algorithm: BAHMAC.Algorithm = .sha256) -> String {
        ba_utf8Data.ba_hmacString(key: Data(key.utf8), algorithm: algorithm)
    }

    /// AES-CBC-PKCS7 加密并返回 Base64 密文。
    ///
    /// - Parameters:
    ///   - key: AES 密钥字符串，UTF-8 后必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量字符串，UTF-8 后必须是 16 字节。
    /// - Returns: Base64 密文字符串。
    func ba_aesCBCEncryptedBase64(key: String, iv: String) throws -> String {
        let encrypted = try ba_utf8Data.ba_aesCBCEncrypted(key: Data(key.utf8), iv: Data(iv.utf8))
        return encrypted.base64EncodedString()
    }

    /// 将 Base64 密文按 AES-CBC-PKCS7 解密为字符串。
    ///
    /// - Parameters:
    ///   - key: AES 密钥字符串，UTF-8 后必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量字符串，UTF-8 后必须是 16 字节。
    /// - Returns: 解密后的 UTF-8 字符串。
    func ba_aesCBCDecryptedFromBase64(key: String, iv: String) throws -> String {
        guard let data = Data(base64Encoded: self) else { throw BACryptoError.stringEncodingFailed }
        let decrypted = try data.ba_aesCBCDecrypted(key: Data(key.utf8), iv: Data(iv.utf8))
        guard let string = String(data: decrypted, encoding: .utf8) else { throw BACryptoError.stringEncodingFailed }
        return string
    }

    /// 基于口令的 AES-256 加密，返回 Base64 密文 —— **推荐的安全默认**。
    ///
    /// 内部用 PBKDF2 从口令派生密钥并使用随机 IV（见 ``BAAES/encrypt(_:password:rounds:)``），
    /// 无需调用方自备 key/iv，也不会出现「口令直当密钥 / 固定 IV」的弱用法。
    ///
    /// - Parameters:
    ///   - password: 口令（UTF-8，不应为空）。
    ///   - rounds: PBKDF2 迭代次数，默认 ``BAAES/defaultPBKDF2Rounds``。
    /// - Returns: Base64 密文（已含还原所需的 salt/iv/rounds 头部）。
    func ba_aesEncrypted(password: String, rounds: UInt32 = BAAES.defaultPBKDF2Rounds) throws -> String {
        let encrypted = try BAAES.encrypt(ba_utf8Data, password: password, rounds: rounds)
        return encrypted.base64EncodedString()
    }

    /// 将 ``ba_aesEncrypted(password:rounds:)`` 产出的 Base64 密文解密为字符串。
    ///
    /// - Parameter password: 加密时所用的同一口令。
    /// - Returns: 解密后的 UTF-8 字符串。
    func ba_aesDecrypted(password: String) throws -> String {
        guard let data = Data(base64Encoded: self) else { throw BACryptoError.stringEncodingFailed }
        let decrypted = try BAAES.decrypt(data, password: password)
        guard let string = String(data: decrypted, encoding: .utf8) else { throw BACryptoError.stringEncodingFailed }
        return string
    }
}
