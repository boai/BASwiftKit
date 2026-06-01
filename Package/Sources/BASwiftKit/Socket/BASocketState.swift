//
//  BASocketState.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 连接状态。
public enum BASocketState: Equatable {
    /// 初始状态，尚未连接。
    case idle
    /// 正在建立连接。
    case connecting
    /// 已连接，可以收发消息。
    case connected
    /// 正在断开连接。
    case disconnecting
    /// 已断开，可携带断开原因。
    case disconnected(Error?)

    public static func == (lhs: BASocketState, rhs: BASocketState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.connecting, .connecting), (.connected, .connected), (.disconnecting, .disconnecting), (.disconnected, .disconnected):
            return true
        default:
            return false
        }
    }
}
