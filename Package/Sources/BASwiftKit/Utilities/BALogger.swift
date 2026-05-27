//
//  BALogger.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// 轻量日志封装。
/// - 控制台彩色输出（仅 Debug 编译生效）
/// - 支持等级过滤
/// - 单例 `BALogger.shared`，也支持单独实例
public final class BALogger {

    /// 日志等级，数值越大优先级越高。
    public enum Level: Int, Comparable {
        /// 详细调试信息。
        case verbose
        /// 调试信息。
        case debug
        /// 普通业务信息。
        case info
        /// 警告信息。
        case warning
        /// 错误信息。
        case error
        /// 比较两个日志等级的优先级。
        public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }

        var symbol: String {
            switch self {
            case .verbose: return "💬"
            case .debug:   return "🛠"
            case .info:    return "ℹ️"
            case .warning: return "⚠️"
            case .error:   return "❌"
            }
        }
    }

    /// 全局共享 logger 实例。
    public static let shared = BALogger()

    /// 低于此等级的日志将被忽略
    public var minLevel: Level = .debug

    /// 是否启用打印（Release 默认关闭）
    public var enabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    /// 创建独立 logger 实例。
    public init() {}

    /// 输出一条指定等级日志。
    ///
    /// - Parameters:
    ///   - message: 日志内容，使用 autoclosure 避免被过滤日志提前求值。
    ///   - level: 日志等级，默认 `.debug`。
    ///   - file: 调用文件路径，默认由编译器填充。
    ///   - function: 调用函数名，默认由编译器填充。
    ///   - line: 调用行号，默认由编译器填充。
    public func ba_log(_ message: @autoclosure () -> Any,
                       level: Level = .debug,
                       file: String = #file,
                       function: String = #function,
                       line: Int = #line) {
        guard enabled, level >= minLevel else { return }
        let filename = (file as NSString).lastPathComponent
        let time = Self.timestamp()
        Swift.print("\(time) \(level.symbol) [\(filename):\(line)] \(function) → \(message())")
    }

    /// 输出 verbose 等级日志。
    public func ba_verbose(_ msg: @autoclosure () -> Any,
                           file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .verbose, file: file, function: function, line: line)
    }

    /// 输出 debug 等级日志。
    public func ba_debug(_ msg: @autoclosure () -> Any,
                         file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .debug, file: file, function: function, line: line)
    }

    /// 输出 info 等级日志。
    public func ba_info(_ msg: @autoclosure () -> Any,
                        file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .info, file: file, function: function, line: line)
    }

    /// 输出 warning 等级日志。
    public func ba_warning(_ msg: @autoclosure () -> Any,
                           file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .warning, file: file, function: function, line: line)
    }

    /// 输出 error 等级日志。
    public func ba_error(_ msg: @autoclosure () -> Any,
                         file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .error, file: file, function: function, line: line)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private static func timestamp() -> String { formatter.string(from: Date()) }
}
