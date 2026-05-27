//
//  String+BASubscript.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

public extension String {
    /// 按整数位置安全获取字符，越界时返回 `nil`。
    ///
    /// - Parameter index: 从 0 开始的字符位置。
    /// - Returns: 对应位置的字符，或 `nil`。
    func ba_character(at index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// 按整数范围安全截取字符串，越界部分会自动裁剪。
    ///
    /// - Parameter range: 从 0 开始的半开区间。
    /// - Returns: 截取后的字符串；无有效交集时返回空字符串。
    func ba_substring(in range: Range<Int>) -> String {
        let lower = max(0, range.lowerBound)
        let upper = min(count, range.upperBound)
        guard lower < upper else { return "" }
        let start = index(startIndex, offsetBy: lower)
        let end = index(startIndex, offsetBy: upper)
        return String(self[start..<end])
    }
}
