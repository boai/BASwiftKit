//
//  BASocketClient.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/28.
//

import Foundation
import Starscream

/// Socket 客户端封装。
///
/// 基于 Starscream 二次封装，提供连接管理、状态观察、消息解析、自动心跳与指数退保重连。
/// 核心职责单一，不耦合具体业务解析逻辑；解析通过 `BASocketParser` 协议注入。
///
/// ```swift
/// let config = BASocketConfiguration(url: URL(string: "wss://echo.websocket.org")!)
/// let client = BASocketClient(configuration: config)
/// client.onEvent = { event in
///     switch event {
///     case .connected: print("已连接")
///     case .message(let msg): print("收到: \(msg.text ?? "")")
///     default: break
///     }
/// }
/// client.connect()
/// ```
public final class BASocketClient {

    /// 连接配置，创建后不可变。
    public let configuration: BASocketConfiguration
    /// 当前连接状态，支持多观察者绑定。
    public let state: BAObservable<BASocketState>
    /// 事件回调。默认在主线程触发。
    public var onEvent: ((BASocketEvent) -> Void)?
    /// 消息解析器数组，收到消息时按顺序尝试解析。
    public var parsers: [BASocketParser]

    private var socket: WebSocket?
    private let lock = NSLock()
    private var reconnectCount = 0
    private var heartbeatTimer: Timer?

    /// 创建 Socket 客户端。
    ///
    /// - Parameters:
    ///   - configuration: 连接配置。
    ///   - parsers: 消息解析器，默认 `[JSON, Text, Binary]`。
    public init(configuration: BASocketConfiguration,
                parsers: [BASocketParser] = BASocketParsers.default) {
        self.configuration = configuration
        self.parsers = parsers
        self.state = BAObservable(.idle)
    }

    deinit {
        invalidateHeartbeat()
        socket?.disconnect()
        socket = nil
    }

    // MARK: - Connection

    /// 建立连接。
    ///
    /// 如果当前已有连接或正在连接，此方法会直接返回。
    public func connect() {
        lock.lock()
        defer { lock.unlock() }

        guard socket == nil else { return }

        var request = URLRequest(url: configuration.url)
        request.timeoutInterval = configuration.timeout
        configuration.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let ws = WebSocket(request: request)
        ws.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }
        socket = ws
        state.update(.connecting)
        ws.connect()
    }

    /// 主动断开连接。
    ///
    /// 断开时会清空重连计数、停止心跳，状态变为 `.disconnected(nil)`。
    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }

        invalidateHeartbeat()
        socket?.disconnect()
        socket = nil
        reconnectCount = 0
        state.update(.disconnected(nil))
    }

    // MARK: - Send

    /// 发送文本消息。
    ///
    /// - Parameters:
    ///   - text: 文本内容。
    ///   - completion: 写入完成回调（不代表对方已收到）。
    public func send(text: String, completion: (() -> Void)? = nil) {
        guard case .connected = state.value else {
            onEvent?(.error(.notConnected))
            completion?()
            return
        }
        socket?.write(string: text, completion: completion)
    }

    /// 发送二进制消息。
    ///
    /// - Parameters:
    ///   - data: 二进制数据。
    ///   - completion: 写入完成回调。
    public func send(data: Data, completion: (() -> Void)? = nil) {
        guard case .connected = state.value else {
            onEvent?(.error(.notConnected))
            completion?()
            return
        }
        socket?.write(data: data, completion: completion)
    }

    /// 发送 Ping 帧。
    ///
    /// - Parameter completion: 写入完成回调。
    public func ping(completion: (() -> Void)? = nil) {
        guard case .connected = state.value else {
            onEvent?(.error(.notConnected))
            completion?()
            return
        }
        socket?.write(ping: Data(), completion: completion)
    }

    // MARK: - Private

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            reconnectCount = 0
            state.update(.connected)
            startHeartbeat()
            onEvent?(.connected)

        case .disconnected(let reason, let code):
            invalidateHeartbeat()
            state.update(.disconnected(BASocketError.underlying(NSError(domain: "BASocket", code: Int(code), userInfo: [NSLocalizedDescriptionKey: reason]))))
            onEvent?(.disconnected(reason, code))
            attemptReconnect()

        case .text(let text):
            if let message = parseText(text) {
                onEvent?(.message(message))
            }

        case .binary(let data):
            if let message = parseBinary(data) {
                onEvent?(.message(message))
            }

        case .ping:
            onEvent?(.ping)

        case .pong:
            onEvent?(.pong)

        case .viabilityChanged(let viable):
            if !viable {
                state.update(.disconnected(nil))
            }

        case .reconnectSuggested:
            attemptReconnect()

        case .cancelled:
            invalidateHeartbeat()
            state.update(.disconnected(nil))
            lock.lock()
            socket = nil
            lock.unlock()

        case .error(let error):
            if let error {
                state.update(.disconnected(error))
                onEvent?(.error(.underlying(error)))
            }

        case .peerClosed:
            invalidateHeartbeat()
            state.update(.disconnected(nil))
            attemptReconnect()
        }
    }

    private func parseText(_ text: String) -> BASocketMessage? {
        for parser in parsers {
            if let message = parser.parse(text) {
                return message
            }
        }
        return nil
    }

    private func parseBinary(_ data: Data) -> BASocketMessage? {
        for parser in parsers {
            if let message = parser.parse(data) {
                return message
            }
        }
        return nil
    }

    private func startHeartbeat() {
        guard configuration.heartbeatInterval > 0 else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.heartbeatTimer?.invalidate()
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: self.configuration.heartbeatInterval, repeats: true) { [weak self] _ in
                self?.socket?.write(ping: Data())
            }
        }
    }

    private func invalidateHeartbeat() {
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
        }
    }

    private func attemptReconnect() {
        guard configuration.maxReconnectAttempts > 0 else { return }
        guard reconnectCount < configuration.maxReconnectAttempts else { return }

        reconnectCount += 1
        let delay = configuration.reconnectDelay * pow(2.0, Double(reconnectCount - 1))
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let shouldReconnect = self.socket == nil || self.state.value == .disconnected(nil)
            self.lock.unlock()
            guard shouldReconnect else { return }
            self.socket = nil
            self.connect()
        }
    }
}
