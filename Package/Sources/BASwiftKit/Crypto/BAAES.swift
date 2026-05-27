//
//  BAAES.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
import CommonCrypto

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
