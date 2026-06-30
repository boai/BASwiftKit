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
    /// 重连代次计数（受 `lock` 保护）。
    /// 每次用户主动 `disconnect()` 时自增，使此前已调度但尚未执行的在途重连作废，
    /// 避免"主动断开后仍被自动重连"。调度重连前捕获当前值，重连 block 执行时校验未变才真正连接。
    private var reconnectGeneration = 0

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
        // 不能走 invalidateHeartbeat()：它内部 DispatchQueue.main.async { [weak self] ... }，
        // deinit 时 self 即将为 nil，闭包成为 no-op，repeats 心跳 Timer 会被 RunLoop 强持有而泄漏空跑。
        // 这里把 timer 取到局部强引用后派发到主线程同步 invalidate（捕获 timer 本身、不依赖 self 存活），
        // 在主线程（即 timer 注册线程）上失效，断开 RunLoop 对 timer 的持有。
        if let timer = heartbeatTimer {
            heartbeatTimer = nil
            if Thread.isMainThread {
                timer.invalidate()
            } else {
                DispatchQueue.main.async { timer.invalidate() }
            }
        }
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
        // 自增重连代次，作废此前已调度的在途重连（见 attemptReconnect）。
        reconnectGeneration += 1
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
            emit(.error(.notConnected))
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
            emit(.error(.notConnected))
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
            emit(.error(.notConnected))
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
            emit(.connected)

        case .disconnected(let reason, let code):
            invalidateHeartbeat()
            clearSocket()
            state.update(.disconnected(BASocketError.underlying(NSError(domain: "BASocket", code: Int(code), userInfo: [NSLocalizedDescriptionKey: reason]))))
            emit(.disconnected(reason, code))
            attemptReconnect()

        case .text(let text):
            if let message = parseText(text) {
                emit(.message(message))
            }

        case .binary(let data):
            if let message = parseBinary(data) {
                emit(.message(message))
            }

        case .ping:
            emit(.ping)

        case .pong:
            emit(.pong)

        case .viabilityChanged(let viable):
            // 连接不可用等同于断开：停心跳、置空 socket 以便 connect() 可重连，并尝试自动重连。
            // 否则心跳会持续 ping 死连接，且 connect() 的 `guard socket == nil` 永远失败。
            if !viable {
                invalidateHeartbeat()
                clearSocket()
                state.update(.disconnected(nil))
                attemptReconnect()
            }

        case .reconnectSuggested:
            attemptReconnect()

        case .cancelled:
            invalidateHeartbeat()
            clearSocket()
            state.update(.disconnected(nil))

        case .error(let error):
            // 出错时与 .disconnected 一致处理：停心跳、置空 socket、尝试重连，
            // 避免心跳继续 ping 死连接、且 connect() 无法重连导致卡死。
            invalidateHeartbeat()
            clearSocket()
            if let error {
                state.update(.disconnected(error))
                emit(.error(.underlying(error)))
            } else {
                state.update(.disconnected(nil))
            }
            attemptReconnect()

        case .peerClosed:
            invalidateHeartbeat()
            clearSocket()
            state.update(.disconnected(nil))
            attemptReconnect()
        }
    }

    /// 在锁内将 socket 置空，使 `connect()` 的 `guard socket == nil` 与 `attemptReconnect` 能正常工作。
    private func clearSocket() {
        lock.lock()
        socket = nil
        lock.unlock()
    }

    /// 统一在主线程触发事件回调，兑现"`onEvent` 默认在主线程触发"的承诺。
    /// Starscream 的回调队列及重连路径都可能在子线程，这里集中切主线程，避免逐处处理。
    private func emit(_ event: BASocketEvent) {
        if Thread.isMainThread {
            onEvent?(event)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onEvent?(event)
            }
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
            let timer = Timer(timeInterval: self.configuration.heartbeatInterval, repeats: true) { [weak self] _ in
                self?.socket?.write(ping: Data())
            }
            // 添加到 .common mode，确保 UIScrollView 滚动时心跳也能正常发送
            RunLoop.main.add(timer, forMode: .common)
            self.heartbeatTimer = timer
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

        lock.lock()
        guard reconnectCount < configuration.maxReconnectAttempts else {
            lock.unlock()
            return
        }
        reconnectCount += 1
        let count = reconnectCount
        // 捕获当前重连代次，用于在 block 执行时检测用户是否已主动 disconnect。
        let generation = reconnectGeneration
        lock.unlock()

        let delay = configuration.reconnectDelay * pow(2.0, Double(count - 1))
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.lock.lock()
            // 代次已变化说明期间发生过主动 disconnect，作废本次在途重连；
            // socket 非 nil 说明已另行连接，无需重复。
            guard self.reconnectGeneration == generation, self.socket == nil else {
                self.lock.unlock()
                return
            }
            self.lock.unlock()
            self.connect()
        }
    }
}
