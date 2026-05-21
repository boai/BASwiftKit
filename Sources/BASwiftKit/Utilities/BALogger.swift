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

    public enum Level: Int, Comparable {
        case verbose, debug, info, warning, error
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

    public init() {}

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

    public func ba_verbose(_ msg: @autoclosure () -> Any,
                           file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .verbose, file: file, function: function, line: line)
    }

    public func ba_debug(_ msg: @autoclosure () -> Any,
                         file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .debug, file: file, function: function, line: line)
    }

    public func ba_info(_ msg: @autoclosure () -> Any,
                        file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .info, file: file, function: function, line: line)
    }

    public func ba_warning(_ msg: @autoclosure () -> Any,
                           file: String = #file, function: String = #function, line: Int = #line) {
        ba_log(msg(), level: .warning, file: file, function: function, line: line)
    }

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
