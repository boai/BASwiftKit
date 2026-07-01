//
//  BAFileSizeFormatter.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation

/// 人类可读的文件大小格式化工具，线程安全（内部使用 ByteCountFormatter）。
///
/// 示例：
/// ```swift
/// BAFileSizeFormatter.string(from: 1_500_000) // → "1.5 MB"
/// BAFileSizeFormatter.string(from: UInt64(2_000_000_000)) // → "2 GB"
/// ```
public enum BAFileSizeFormatter {
    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useAll]
        f.countStyle = .file
        f.includesUnit = true
        f.isAdaptive = true
        f.zeroPadsFractionDigits = false
        return f
    }()

    /// 将 Int64 字节数格式化为人类可读字符串。线程安全。
    public static func string(from bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }

    /// 将 UInt64 字节数格式化为人类可读字符串。线程安全。
    public static func string(from bytes: UInt64) -> String {
        formatter.string(fromByteCount: Int64(bytes))
    }
}
