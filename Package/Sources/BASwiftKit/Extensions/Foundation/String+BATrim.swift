//
//  String+BATrim.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension String {
    /// 去掉首尾空白和换行。
    var ba_trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 去除所有空白和换行字符，适合处理手机号、验证码等不应包含空白的输入。
    var ba_compact: String {
        components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// 是否为空字符串，或只包含空白字符、换行符。
    var ba_isBlank: Bool {
        ba_trimmed.isEmpty
    }
}
