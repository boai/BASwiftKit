//
//  BASocketMessageType.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 消息类型。
public enum BASocketMessageType: Equatable {
    /// 纯文本消息。
    case text
    /// JSON 消息。
    case json
    /// 二进制消息。
    case binary
    /// Ping 帧。
    case ping
    /// Pong 帧。
    case pong
}
