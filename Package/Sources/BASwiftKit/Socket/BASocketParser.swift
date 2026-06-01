//
//  BASocketParser.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 消息解析器协议。
///
/// 实现自定义解析逻辑后注入 `BASocketClient.parsers`，收到消息时按数组顺序尝试解析，
/// 第一个返回非 `nil` 的结果作为最终消息类型。
public protocol BASocketParser {
    /// 尝试把文本解析为 `BASocketMessage`。
    ///
    /// - Parameter text: 收到的文本内容。
    /// - Returns: 解析成功返回消息，失败返回 `nil` 让下一个解析器继续尝试。
    func parse(_ text: String) -> BASocketMessage?

    /// 尝试把二进制数据解析为 `BASocketMessage`。
    ///
    /// - Parameter data: 收到的二进制数据。
    /// - Returns: 解析成功返回消息，失败返回 `nil` 让下一个解析器继续尝试。
    func parse(_ data: Data) -> BASocketMessage?
}
