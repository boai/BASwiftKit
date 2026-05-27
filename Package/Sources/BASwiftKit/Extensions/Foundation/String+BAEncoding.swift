//
//  String+BAEncoding.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension String {
    /// UTF-8 数据，便于和加密、网络 Body、文件写入等 Data API 衔接。
    var ba_utf8Data: Data { Data(utf8) }

    /// UTF-8 字符串的 Base64 编码结果。
    var ba_base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    /// 将当前字符串作为 Base64 内容解码为 UTF-8 字符串。
    var ba_base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// MD5 摘要（32 位小写）。仅建议兼容旧接口，新接口优先使用 `ba_sha256` 或 `ba_hmac`。
    var ba_md5: String {
        ba_utf8Data.ba_md5String
    }
}
