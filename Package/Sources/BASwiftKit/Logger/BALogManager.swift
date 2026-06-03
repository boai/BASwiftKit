//
//  BALogManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

import Foundation

/// 全页面日志管理器。
///
/// 提供统一的日志入口，自动将日志写入 SQLite 数据库。
/// 调用 `start()` 后会自动捕获 `print`/`NSLog` 输出并记录为 `.system` 级别日志。
///
/// ```swift
/// // AppDelegate 中启动
/// BALogManager.shared.start()
///
/// // 手动打点
/// BALogManager.shared.log(.info, "用户登录成功")
/// BALogManager.shared.log(.error, "网络请求失败: timeout")
/// ```
public final class BALogManager {

    /// 全局共享实例。
    public static let shared = BALogManager()

    /// 底层数据库。
    public let database: BALogSQLiteStore

    /// 当前是否正在捕获系统输出。
    public private(set) var isCapturing: Bool = false

    /// 日志级别过滤：低于此级别的日志不会被写入数据库。默认 `.debug`（全量写入）。
    public var minimumLevel: BALogLevel = .debug

    private let captureQueue = DispatchQueue(label: "com.baswiftkit.logmanager.capture", qos: .utility)
    private var capturePipe: Pipe?
    private var captureHandle: FileHandle?
    private var originalStdoutFD: Int32 = -1
    private var originalStderrFD: Int32 = -1

    // MARK: - Init

    /// 创建日志管理器。
    ///
    /// - Parameter database: 日志数据库，默认使用 `BALogSQLiteStore.shared`。
    public init(database: BALogSQLiteStore = .shared) {
        self.database = database
    }

    // MARK: - Start / Stop

    /// 启动日志系统。
    ///
    /// 该方法会：
    /// 1. 开启 print/NSLog 输出捕获（重定向 stdout/stderr）
    /// 2. 后续所有 `print()`、`NSLog()` 输出都会自动写入数据库
    ///
    /// 建议在 `AppDelegate.application(_:didFinishLaunchingWithOptions:)` 中调用。
    public func start() {
        guard !isCapturing else { return }
        startCapturing()
        isCapturing = true
    }

    /// 停止日志系统并恢复 stdout/stderr。
    public func stop() {
        guard isCapturing else { return }
        stopCapturing()
        isCapturing = false
    }

    // MARK: - Logging API

    /// 记录一条日志。
    ///
    /// - Parameters:
    ///   - level: 日志级别。
    ///   - message: 日志内容。
    ///   - file: 调用方文件名，默认自动填充。
    ///   - line: 调用方行号。
    ///   - function: 调用方函数名。
    public func log(_ level: BALogLevel,
                    _ message: String,
                    file: String = #file,
                    line: Int = #line,
                    function: String = #function) {
        guard levelWeight(level) >= levelWeight(minimumLevel) else { return }
        let ctx = encodeContext(file: file, line: line, function: function)
        let now = Date().timeIntervalSince1970
        database.insert(timestamp: now, level: level, message: message, context: ctx)
    }

    /// 记录页面浏览日志。
    ///
    /// - Parameters:
    ///   - page: 页面名称（通常是 ViewController 类名）。
    ///   - title: 页面标题。
    public func logPageView(page: String, title: String? = nil) {
        var extra: [String: String] = ["page": page]
        if let t = title { extra["title"] = t }
        let ctx = encodeContext(dict: extra)
        let now = Date().timeIntervalSince1970
        database.insert(timestamp: now, level: .pageView, message: "进入页面: \(page)", context: ctx)
    }

    /// 记录按钮点击日志。
    ///
    /// - Parameters:
    ///   - buttonTitle: 按钮标题或标识。
    ///   - page: 所在页面名称。
    public func logButtonClick(buttonTitle: String, page: String? = nil) {
        var extra: [String: String] = ["button": buttonTitle]
        if let p = page { extra["page"] = p }
        let ctx = encodeContext(dict: extra)
        let now = Date().timeIntervalSince1970
        database.insert(timestamp: now, level: .buttonClick, message: "点击按钮: \(buttonTitle)", context: ctx)
    }

    /// 记录缓存操作日志。
    ///
    /// - Parameters:
    ///   - type: 操作类型（如 `.set` / `.getHit` / `.getMiss` / `.remove` / `.clear` / `.cleanExpired`）。
    ///   - key: 缓存键。
    ///   - strategy: 缓存策略（如 "hybrid" / "memory" / "disk"）。
    ///   - size: 数据大小（字节），可选。
    ///   - note: 附加说明，可选。
    public func logCache(type: BACacheOperationType,
                         key: String,
                         strategy: String = "hybrid",
                         size: Int? = nil,
                         note: String? = nil) {
        var extra: [String: String] = [
            "cacheType": type.rawValue,
            "key": key,
            "strategy": strategy,
        ]
        if let s = size { extra["size"] = "\(s)" }
        if let n = note { extra["note"] = n }

        let ctx = encodeContext(dict: extra)
        let now = Date().timeIntervalSince1970
        let summary: String
        if let s = size {
            summary = "[缓存] \(type.displayName) key=\(key) strategy=\(strategy) size=\(s)B"
        } else {
            summary = "[缓存] \(type.displayName) key=\(key) strategy=\(strategy)"
        }
        database.insert(timestamp: now, level: .cache, message: summary, context: ctx)
    }

    /// 记录网络请求日志。
    ///
    /// - Parameters:
    ///   - url: 请求 URL。
    ///   - method: HTTP 方法（GET / POST / PUT / DELETE …）。
    ///   - statusCode: HTTP 状态码。
    ///   - duration: 请求耗时（秒）。
    ///   - requestSize: 请求体大小（字节），可选。
    ///   - responseSize: 响应体大小（字节），可选。
    ///   - error: 请求错误描述，成功时为 `nil`。
    public func logNetwork(url: String,
                           method: String,
                           statusCode: Int,
                           duration: TimeInterval,
                           requestSize: Int? = nil,
                           responseSize: Int? = nil,
                           error: String? = nil) {
        var extra: [String: String] = [
            "url": url,
            "method": method,
            "statusCode": "\(statusCode)",
            "duration": String(format: "%.3f", duration),
        ]
        if let rs = requestSize { extra["requestSize"] = "\(rs)" }
        if let rs = responseSize { extra["responseSize"] = "\(rs)" }
        if let err = error { extra["error"] = err }

        let ctx = encodeContext(dict: extra)
        let now = Date().timeIntervalSince1970
        let summary: String
        if let err = error {
            summary = "\(method) \(url) → \(statusCode) 失败: \(err)"
        } else {
            summary = "\(method) \(url) → \(statusCode) \(String(format: "%.0fms", duration * 1000))"
        }
        database.insert(timestamp: now, level: .network, message: summary, context: ctx)
    }

    // MARK: - Print Capture

    private func startCapturing() {
        let pipe = Pipe()
        capturePipe = pipe

        // 保存原始 fd 并重定向 stdout
        originalStdoutFD = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        // 重定向 stderr（NSLog 输出目标）
        originalStderrFD = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // 后台读取 pipe
        captureHandle = pipe.fileHandleForReading
        captureHandle?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                let now = Date().timeIntervalSince1970
                self.database.insert(timestamp: now, level: .system, message: output, context: nil)
            }
        }
    }

    private func stopCapturing() {
        captureHandle?.readabilityHandler = nil
        captureHandle = nil
        capturePipe = nil

        if originalStdoutFD >= 0 {
            dup2(originalStdoutFD, STDOUT_FILENO)
            close(originalStdoutFD)
            originalStdoutFD = -1
        }
        if originalStderrFD >= 0 {
            dup2(originalStderrFD, STDERR_FILENO)
            close(originalStderrFD)
            originalStderrFD = -1
        }
    }

    // MARK: - Helpers

    private func levelWeight(_ level: BALogLevel) -> Int {
        level.levelValue
    }

    private func encodeContext(file: String, line: Int, function: String) -> String? {
        let fileName = (file as NSString).lastPathComponent
        let dict: [String: Any] = ["file": fileName, "line": line, "function": function]
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }

    private func encodeContext(dict: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }
}
