//
//  BASocketEvent.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 事件。
///
/// 通过 `BASocketClient.onEvent` 统一回调，业务层按 `switch` 处理即可。
public enum BASocketEvent: Equatable {
    /// 连接成功。
    case connected
    /// 连接断开，携带原因与关闭码。
    case disconnected(String, UInt16)
    /// 收到消息。
    case message(BASocketMessage)
    /// 发生错误。
    case error(BASocketError)
    /// 收到 Ping。
    case ping
    /// 收到 Pong。
    case pong

    public static func == (lhs: BASocketEvent, rhs: BASocketEvent) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected), (.ping, .ping), (.pong, .pong):
            return true
        case let (.disconnected(lr, lc), .disconnected(rr, rc)):
            return lr == rr && lc == rc
        case let (.message(lm), .message(rm)):
            return lm == rm
        case let (.error(le), .error(re)):
            return le == re
        default:
            return false
        }
    }
}
