//
//  BASocketParsers.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// JSON 消息解析器。
///
/// 当文本内容可被反序列化为 JSON 时返回 `.json` 类型消息。
public struct BAJSONSocketParser: BASocketParser {
    public init() {}

    public func parse(_ text: String) -> BASocketMessage? {
        guard let data = text.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else { return nil }
        return BASocketMessage(type: .json, rawData: data)
    }

    public func parse(_ data: Data) -> BASocketMessage? {
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else { return nil }
        return BASocketMessage(type: .json, rawData: data)
    }
}

/// 纯文本消息解析器。
///
/// 任何 UTF-8 可解码的内容都会返回 `.text` 类型消息。
public struct BATextSocketParser: BASocketParser {
    public init() {}

    public func parse(_ text: String) -> BASocketMessage? {
        guard let data = text.data(using: .utf8) else { return nil }
        return BASocketMessage(type: .text, rawData: data)
    }

    public func parse(_ data: Data) -> BASocketMessage? {
        guard String(data: data, encoding: .utf8) != nil else { return nil }
        return BASocketMessage(type: .text, rawData: data)
    }
}

/// 二进制消息解析器。
///
/// 任何二进制数据都会返回 `.binary` 类型消息，通常放在解析链末尾作为兜底。
public struct BABinarySocketParser: BASocketParser {
    public init() {}

    public func parse(_ text: String) -> BASocketMessage? { nil }

    public func parse(_ data: Data) -> BASocketMessage? {
        BASocketMessage(type: .binary, rawData: data)
    }
}

/// 内置解析器组合。
public enum BASocketParsers {
    /// 默认解析链：先尝试 JSON，再尝试 Text，最后兜底 Binary。
    public static var `default`: [BASocketParser] {
        [BAJSONSocketParser(), BATextSocketParser(), BABinarySocketParser()]
    }
}
