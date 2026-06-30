//
//  BAAES.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
import CommonCrypto
import Security

/// AES 对称加解密工具。
///
/// 当前提供移动端常用的 AES-CBC + PKCS7Padding 封装。
/// key 长度必须是 16/24/32 字节，分别对应 AES-128/192/256；IV 必须是 16 字节。
/// CBC 模式要求调用方为不同消息使用不可预测 IV，避免重复 IV 导致安全风险。
public enum BAAES {
    /// AES-CBC-PKCS7 加密。
    ///
    /// - Parameters:
    ///   - data: 明文数据。
    ///   - key: AES 密钥，长度必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量，长度必须是 16 字节。
    /// - Returns: 密文数据。
    /// - Throws: key/iv 长度错误或加密失败。
    public static func cbcEncrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        try cbcCrypt(data, key: key, iv: iv, operation: CCOperation(kCCEncrypt))
    }

    /// AES-CBC-PKCS7 解密。
    ///
    /// - Parameters:
    ///   - data: 密文数据。
    ///   - key: AES 密钥，长度必须是 16/24/32 字节。
    ///   - iv: CBC 初始向量，长度必须是 16 字节。
    /// - Returns: 明文数据。
    /// - Throws: key/iv 长度错误或解密失败。
    public static func cbcDecrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        try cbcCrypt(data, key: key, iv: iv, operation: CCOperation(kCCDecrypt))
    }

    private static func cbcCrypt(_ data: Data, key: Data, iv: Data, operation: CCOperation) throws -> Data {
        guard [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(key.count) else {
            throw BACryptoError.invalidKeyLength
        }
        guard iv.count == kCCBlockSizeAES128 else { throw BACryptoError.invalidIVLength }

        let outputCapacity = data.count + kCCBlockSizeAES128
        var output = Data(count: outputCapacity)
        var outputLength = 0
        let status = output.withUnsafeMutableBytes { outputBuffer in
            data.withUnsafeBytes { dataBuffer in
                key.withUnsafeBytes { keyBuffer in
                    iv.withUnsafeBytes { ivBuffer in
                        CCCrypt(operation,
                                CCAlgorithm(kCCAlgorithmAES),
                                CCOptions(kCCOptionPKCS7Padding),
                                keyBuffer.baseAddress,
                                key.count,
                                ivBuffer.baseAddress,
                                dataBuffer.baseAddress,
                                data.count,
                                outputBuffer.baseAddress,
                                outputCapacity,
                                &outputLength)
                    }
                }
            }
        }
        guard status == kCCSuccess else { throw BACryptoError.cryptFailed(status: status) }
        output.removeSubrange(outputLength..<output.count)
        return output
    }
}

// MARK: - Password-Based Encryption（口令加密，安全默认）

public extension BAAES {

    /// 默认 PBKDF2 迭代次数。次数越高抗暴力破解越强，但加解密越慢。
    static let defaultPBKDF2Rounds: UInt32 = 100_000

    /// 基于口令的 AES-256-CBC 加密 —— **推荐的安全默认**。
    ///
    /// 与需要调用方自备 key/iv 的 `cbcEncrypt(_:key:iv:)` 不同，本方法：
    /// - 用 **PBKDF2-HMAC-SHA256** 从「口令 + 随机 salt」派生 256 位密钥（而非把口令字节直接当密钥）；
    /// - 为每次加密生成**随机 IV**。
    ///
    /// 因此**相同口令 + 相同明文每次都得到不同密文**，规避「固定 IV」与「弱口令直当密钥」的安全风险。
    ///
    /// 输出为**自描述格式**（便于持久化/传输后原样解密，无需另存 salt/iv/rounds）：
    /// ```
    /// 版本(1B=0x01) | rounds(4B 大端) | salt(16B) | iv(16B) | 密文
    /// ```
    ///
    /// - Parameters:
    ///   - data: 明文数据。
    ///   - password: 口令（任意长度，按 UTF-8 处理；不应为空）。
    ///   - rounds: PBKDF2 迭代次数，默认 ``defaultPBKDF2Rounds``。
    /// - Returns: 含头部的密文数据（可直接 Base64 后存储/传输）。
    /// - Throws: 随机数生成 / 密钥派生 / 加密失败时抛出对应 ``BACryptoError``。
    static func encrypt(_ data: Data, password: String, rounds: UInt32 = defaultPBKDF2Rounds) throws -> Data {
        let salt = try randomBytes(count: saltLength)
        let iv = try randomBytes(count: ivLength)
        let key = try deriveKey(password: password, salt: salt, rounds: rounds, length: kCCKeySizeAES256)
        let ciphertext = try cbcEncrypt(data, key: key, iv: iv)

        var output = Data()
        output.append(formatVersion)
        var roundsBE = rounds.bigEndian
        withUnsafeBytes(of: &roundsBE) { output.append(contentsOf: $0) }
        output.append(salt)
        output.append(iv)
        output.append(ciphertext)
        return output
    }

    /// 解密由 ``encrypt(_:password:rounds:)`` 产出的密文。
    ///
    /// 自动从密文头部读取 rounds/salt/iv 还原密钥，无需调用方记忆这些参数。
    ///
    /// - Parameters:
    ///   - data: 含头部的密文数据。
    ///   - password: 加密时所用的同一口令。
    /// - Returns: 明文数据。
    /// - Throws: 密文格式非法 / 密钥派生失败 / 解密失败（口令错误等）时抛出对应 ``BACryptoError``。
    static func decrypt(_ data: Data, password: String) throws -> Data {
        let headerLength = 1 + 4 + saltLength + ivLength
        guard data.count > headerLength else { throw BACryptoError.invalidCipherFormat }

        var cursor = data.startIndex
        let version = data[cursor]
        cursor += 1
        guard version == formatVersion else { throw BACryptoError.invalidCipherFormat }

        // rounds：4 字节大端。
        var rounds: UInt32 = 0
        for _ in 0..<4 {
            rounds = (rounds << 8) | UInt32(data[cursor])
            cursor += 1
        }

        let salt = Data(data[cursor..<cursor + saltLength])
        cursor += saltLength
        let iv = Data(data[cursor..<cursor + ivLength])
        cursor += ivLength
        let ciphertext = Data(data[cursor...])

        let key = try deriveKey(password: password, salt: salt, rounds: rounds, length: kCCKeySizeAES256)
        return try cbcDecrypt(ciphertext, key: key, iv: iv)
    }
}

// MARK: - Private Helpers

private extension BAAES {

    /// 密文格式版本号。
    static var formatVersion: UInt8 { 0x01 }
    /// PBKDF2 salt 字节数。
    static var saltLength: Int { 16 }
    /// CBC IV 字节数（等于 AES 块大小）。
    static var ivLength: Int { kCCBlockSizeAES128 }

    /// 生成密码学安全随机字节。
    static func randomBytes(count: Int) throws -> Data {
        var bytes = Data(count: count)
        let status = bytes.withUnsafeMutableBytes { buffer -> Int32 in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, count, base)
        }
        guard status == errSecSuccess else { throw BACryptoError.randomGenerationFailed }
        return bytes
    }

    /// 用 PBKDF2-HMAC-SHA256 从口令派生固定长度密钥。
    static func deriveKey(password: String, salt: Data, rounds: UInt32, length: Int) throws -> Data {
        let passwordData = Data(password.utf8)
        var derived = Data(count: length)

        let status = derived.withUnsafeMutableBytes { derivedBuffer -> Int32 in
            salt.withUnsafeBytes { saltBuffer -> Int32 in
                passwordData.withUnsafeBytes { pwBuffer -> Int32 in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pwBuffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        rounds,
                        derivedBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        length
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw BACryptoError.keyDerivationFailed }
        return derived
    }
}
