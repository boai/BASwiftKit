//
//  BARegexValidator.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// 常用正则校验工具。
///
/// 提供手机号、邮箱、身份证、银行卡、URL、密码强度等常见业务输入校验，
/// 也支持传入自定义正则表达式进行匹配。
public enum BARegexValidator {

    /// 常用正则表达式集合。
    public enum Pattern {
        /// 邮箱地址，校验本地部分、域名和顶级域名的基本格式。
        public static let email = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        /// 中国大陆手机号，11 位数字，号段以 13-19 开头。
        public static let chinaMobile = #"^1[3-9]\d{9}$"#
        /// 中国大陆身份证号，支持 15 位和 18 位，18 位最后一位可为 X/x。
        public static let chinaIDCard = #"^(\d{15}|\d{17}[0-9Xx])$"#
        /// 银行卡号，12 到 19 位数字。
        public static let bankCard = #"^\d{12,19}$"#
        /// HTTP/HTTPS URL。
        public static let httpURL = #"^https?://[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]+$"#
        /// IPv4 地址，仅校验 0-255 四段格式。
        public static let ipv4 = #"^(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$"#
        /// 6 位数字验证码。
        public static let verificationCode6 = #"^\d{6}$"#
        /// 中文字符。
        public static let chinese = #"^[一-龥]+$"#
        /// 用户名：字母开头，允许字母、数字、下划线，长度 4-20。
        public static let username = #"^[A-Za-z][A-Za-z0-9_]{3,19}$"#
        /// 强密码：至少 8 位，包含大小写字母和数字，可包含常见符号。
        public static let strongPassword = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d`~!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]{8,}$"#
    }

    // MARK: - 正则缓存（性能优化）

    /// 已编译正则的缓存。
    ///
    /// `NSRegularExpression(pattern:)` 的编译成本较高，而校验方法常被高频调用（且 pattern 多为固定常量），
    /// 这里按「pattern + options」缓存已编译实例避免重复编译。`NSRegularExpression` 自身的匹配是线程安全的，
    /// 仅缓存字典的读写需要保护，故用一把 `NSLock` 串行化访问。
    private static var regexCache: [String: NSRegularExpression] = [:]
    private static let regexCacheLock = NSLock()

    /// 获取（或编译并缓存）指定 pattern + options 对应的正则。
    ///
    /// - Returns: 编译成功返回正则实例；pattern 非法返回 `nil`（与原 `try?` 行为一致）。
    private static func cachedRegex(pattern: String,
                                    options: NSRegularExpression.Options) -> NSRegularExpression? {
        // 缓存 key 需区分 options，否则不同选项会错误复用同一实例。
        let key = "\(options.rawValue)|\(pattern)"
        regexCacheLock.lock()
        defer { regexCacheLock.unlock() }
        if let cached = regexCache[key] { return cached }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        regexCache[key] = regex
        return regex
    }

    /// 使用自定义正则进行完整匹配。
    ///
    /// - Parameters:
    ///   - text: 待校验文本。
    ///   - pattern: 正则表达式。建议使用 `^` 和 `$` 明确完整匹配范围。
    ///   - options: 正则选项，默认空。
    /// - Returns: 命中返回 `true`；正则非法或未命中返回 `false`。
    public static func ba_matches(_ text: String,
                                  pattern: String,
                                  options: NSRegularExpression.Options = []) -> Bool {
        // 优化：复用已编译正则，避免每次调用都重新编译 pattern。
        guard let regex = cachedRegex(pattern: pattern, options: options) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return false }
        return match.range.location == range.location && match.range.length == range.length
    }

    /// 校验邮箱地址。
    public static func ba_isEmail(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.email)
    }

    /// 校验中国大陆手机号。
    public static func ba_isChinaMobile(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.chinaMobile)
    }

    /// 校验中国大陆身份证号格式。
    public static func ba_isChinaIDCard(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.chinaIDCard)
    }

    /// 校验银行卡号格式。
    public static func ba_isBankCard(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.bankCard)
    }

    /// 校验 HTTP/HTTPS URL。
    public static func ba_isHTTPURL(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.httpURL)
    }

    /// 校验 IPv4 地址。
    public static func ba_isIPv4(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.ipv4)
    }

    /// 校验 6 位数字验证码。
    public static func ba_isVerificationCode6(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.verificationCode6)
    }

    /// 校验是否全部为中文字符。
    public static func ba_isChinese(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.chinese)
    }

    /// 校验用户名格式。
    public static func ba_isUsername(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.username)
    }

    /// 校验强密码格式。
    public static func ba_isStrongPassword(_ text: String) -> Bool {
        ba_matches(text, pattern: Pattern.strongPassword)
    }
}

public extension String {
    /// 使用自定义正则进行完整匹配。
    ///
    /// - Parameters:
    ///   - pattern: 正则表达式。建议使用 `^` 和 `$` 明确完整匹配范围。
    ///   - options: 正则选项，默认空。
    /// - Returns: 命中返回 `true`；正则非法或未命中返回 `false`。
    func ba_matchesRegex(_ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        BARegexValidator.ba_matches(self, pattern: pattern, options: options)
    }

    /// 是否为中国大陆身份证号格式。
    var ba_isChinaIDCard: Bool { BARegexValidator.ba_isChinaIDCard(self) }

    /// 是否为银行卡号格式。
    var ba_isBankCard: Bool { BARegexValidator.ba_isBankCard(self) }

    /// 是否为 HTTP/HTTPS URL。
    var ba_isHTTPURL: Bool { BARegexValidator.ba_isHTTPURL(self) }

    /// 是否为 IPv4 地址。
    var ba_isIPv4: Bool { BARegexValidator.ba_isIPv4(self) }

    /// 是否为 6 位数字验证码。
    var ba_isVerificationCode6: Bool { BARegexValidator.ba_isVerificationCode6(self) }

    /// 是否全部为中文字符。
    var ba_isChinese: Bool { BARegexValidator.ba_isChinese(self) }

    /// 是否符合用户名格式：字母开头，允许字母、数字、下划线，长度 4-20。
    var ba_isUsername: Bool { BARegexValidator.ba_isUsername(self) }

    /// 是否符合强密码格式：至少 8 位，包含大小写字母和数字。
    var ba_isStrongPassword: Bool { BARegexValidator.ba_isStrongPassword(self) }
}
