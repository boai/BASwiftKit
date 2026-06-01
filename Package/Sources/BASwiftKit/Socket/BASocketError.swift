//
//  BASocketError.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 错误。
public enum BASocketError: Error, Equatable {
    /// URL 无效。
    case invalidURL
    /// 未连接或连接已断开，无法发送消息。
    case notConnected
    /// 消息编码失败。
    case encodingFailed
    /// 底层错误。
    case underlying(Error)
    /// 未知错误。
    case unknown

    public static func == (lhs: BASocketError, rhs: BASocketError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL), (.notConnected, .notConnected), (.encodingFailed, .encodingFailed), (.unknown, .unknown):
            return true
        case let (.underlying(l), .underlying(r)):
            return (l as NSError).domain == (r as NSError).domain && (l as NSError).code == (r as NSError).code
        default:
            return false
        }
    }
}
