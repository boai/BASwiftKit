//
//  BASocketMessage.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 接收到的消息。
///
/// 内部保留原始 `Data`，上层可通过 `text`、`json`、`dictionary` 等便利属性读取。
public struct BASocketMessage: Equatable {
    /// 消息类型。
    public let type: BASocketMessageType
    /// 原始二进制数据。
    public let rawData: Data

    /// 文本内容，仅在 UTF-8 可解码时有效。
    public var text: String? {
        String(data: rawData, encoding: .utf8)
    }

    /// JSON 对象，仅在消息可被反序列化为字典时有效。
    public var dictionary: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: rawData)) as? [String: Any]
    }

    /// JSON 数组，仅在消息可被反序列化为数组时有效。
    public var array: [Any]? {
        (try? JSONSerialization.jsonObject(with: rawData)) as? [Any]
    }

    /// 创建消息。
    ///
    /// - Parameters:
    ///   - type: 消息类型。
    ///   - rawData: 原始二进制数据。
    public init(type: BASocketMessageType, rawData: Data) {
        self.type = type
        self.rawData = rawData
    }

    public static func == (lhs: BASocketMessage, rhs: BASocketMessage) -> Bool {
        lhs.type == rhs.type && lhs.rawData == rhs.rawData
    }
}
