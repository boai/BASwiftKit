//
//  String+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation
import CommonCrypto
#if canImport(UIKit)
import UIKit
#endif

public extension String {

    // MARK: - Trim / Empty

    /// 去掉首尾空白和换行
    var ba_trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 去除所有空白字符
    var ba_compact: String {
        components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// 是否为空串或仅含空白
    var ba_isBlank: Bool {
        ba_trimmed.isEmpty
    }

    // MARK: - Validation

    /// 简易邮箱校验
    var ba_isEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// 中国大陆手机号校验（11 位，1 开头）
    var ba_isChinaMobile: Bool {
        let pattern = #"^1[3-9]\d{9}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// URL 格式校验（仅校验 scheme 是否存在）
    var ba_isURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil
    }

    /// 仅由数字组成
    var ba_isPureDigits: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    // MARK: - Encoding

    /// Base64 编码
    var ba_base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    /// Base64 解码
    var ba_base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// MD5 摘要（32 位小写）
    var ba_md5: String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Subscript

    /// 安全下标取字符
    func ba_character(at index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// 安全切片，越界自动裁剪
    func ba_substring(in range: Range<Int>) -> String {
        let lower = max(0, range.lowerBound)
        let upper = min(count, range.upperBound)
        guard lower < upper else { return "" }
        let start = index(startIndex, offsetBy: lower)
        let end = index(startIndex, offsetBy: upper)
        return String(self[start..<end])
    }

    #if canImport(UIKit)
    // MARK: - Size

    /// 按字体计算单行宽度
    func ba_width(font: UIFont) -> CGFloat {
        let attr = [NSAttributedString.Key.font: font]
        return (self as NSString).size(withAttributes: attr).width
    }

    /// 按字体和最大宽度计算多行高度
    func ba_height(font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let bounding = (self as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounding.height)
    }
    #endif
}
