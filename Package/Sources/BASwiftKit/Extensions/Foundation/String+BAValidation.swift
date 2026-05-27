//
//  String+BAValidation.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension String {
    /// 简易邮箱格式校验，适合表单输入的前置判断。
    var ba_isEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// 中国大陆手机号格式校验，要求 11 位、1 开头、第二位为 3-9。
    var ba_isChinaMobile: Bool {
        let pattern = #"^1[3-9]\d{9}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// URL 格式校验，仅判断字符串能否构成 URL 且包含 scheme。
    var ba_isURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil
    }

    /// 是否仅由数字字符组成，空字符串返回 `false`。
    var ba_isPureDigits: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }
}
