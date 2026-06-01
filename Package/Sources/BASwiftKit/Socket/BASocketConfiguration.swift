//
//  BASocketConfiguration.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation

/// Socket 连接配置。
///
/// 创建后可作为 `BASocketClient` 的初始化参数，控制连接地址、超时、心跳与重连策略。
public struct BASocketConfiguration {
    /// 目标服务器地址。
    public let url: URL
    /// 连接超时，默认 10 秒。
    public let timeout: TimeInterval
    /// 心跳间隔，小于等于 0 时不发送心跳。默认 30 秒。
    public let heartbeatInterval: TimeInterval
    /// 最大重连次数，0 表示不重连。默认 5 次。
    public let maxReconnectAttempts: Int
    /// 首次重连延迟，后续按指数退避翻倍。默认 1 秒。
    public let reconnectDelay: TimeInterval
    /// 请求头，例如授权 Token 等。
    public let headers: [String: String]

    /// 创建 Socket 配置。
    ///
    /// - Parameters:
    ///   - url: 目标服务器地址。
    ///   - timeout: 连接超时。
    ///   - heartbeatInterval: 心跳间隔，小于等于 0 时关闭心跳。
    ///   - maxReconnectAttempts: 最大重连次数。
    ///   - reconnectDelay: 首次重连延迟。
    ///   - headers: 自定义请求头。
    public init(url: URL,
                timeout: TimeInterval = 10,
                heartbeatInterval: TimeInterval = 30,
                maxReconnectAttempts: Int = 5,
                reconnectDelay: TimeInterval = 1,
                headers: [String: String] = [:]) {
        self.url = url
        self.timeout = timeout
        self.heartbeatInterval = heartbeatInterval
        self.maxReconnectAttempts = maxReconnectAttempts
        self.reconnectDelay = reconnectDelay
        self.headers = headers
    }
}
