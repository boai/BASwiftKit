//
//  BALogModels.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

import Foundation

/// 日志级别。
public enum BALogLevel: String, Codable, CaseIterable {
    /// 调试信息，仅开发环境输出。
    case debug
    /// 常规信息。
    case info
    /// 警告。
    case warning
    /// 错误。
    case error
    /// 页面浏览（自动采集）。
    case pageView
    /// 按钮点击（自动采集）。
    case buttonClick
    /// 网络请求（自动采集）。
    case network
    /// 缓存操作（自动采集）。
    case cache
    /// 系统 print/NSLog 捕获。
    case system

    /// 展示用中文名称。
    public var displayName: String {
        switch self {
        case .debug:      return "调试"
        case .info:       return "信息"
        case .warning:    return "警告"
        case .error:      return "错误"
        case .pageView:   return "页面浏览"
        case .buttonClick: return "按钮点击"
        case .network:    return "网络请求"
        case .cache:      return "缓存操作"
        case .system:     return "系统输出"
        }
    }

    /// 日志级别对应的数值，数值越大级别越高，可用于排序比较或接口返回。
    ///
    /// | 级别 | 值 |
    /// |------|-----|
    /// | `.debug` | 0 |
    /// | `.info` | 1 |
    /// | `.system` | 2 |
    /// | `.network` | 3 |
    /// | `.cache` | 4 |
    /// | `.pageView` | 5 |
    /// | `.buttonClick` | 6 |
    /// | `.warning` | 7 |
    /// | `.error` | 8 |
    public var levelValue: Int {
        switch self {
        case .debug:       return 0
        case .info:        return 1
        case .system:      return 2
        case .network:     return 3
        case .cache:       return 4
        case .pageView:    return 5
        case .buttonClick: return 6
        case .warning:     return 7
        case .error:       return 8
        }
    }
}

/// 缓存操作类型，用于日志搜索过滤和接口返回。
///
/// 每个缓存日志都携带一个操作类型，方便按类型筛选日志。
public enum BACacheOperationType: String, Codable, CaseIterable {
    /// 写入缓存。
    case set
    /// 读取命中。
    case getHit
    /// 读取未命中。
    case getMiss
    /// 删除指定缓存。
    case remove
    /// 清空全部缓存。
    case clear
    /// 清理过期缓存。
    case cleanExpired

    /// 展示用中文名称。
    public var displayName: String {
        switch self {
        case .set:          return "写入缓存"
        case .getHit:       return "读取命中"
        case .getMiss:      return "读取未命中"
        case .remove:       return "删除缓存"
        case .clear:        return "清空缓存"
        case .cleanExpired: return "清理过期"
        }
    }
}

/// 一条日志记录。
public struct BALogEntry: Codable, Equatable {
    /// 自增主键。
    public let id: Int64
    /// Unix 时间戳（秒）。
    public let timestamp: TimeInterval
    /// 日期字符串（"yyyy-MM-dd"），用于按天查询。
    public let dateString: String
    /// 日志级别。
    public let level: BALogLevel
    /// 日志类型数值（对应 `BALogLevel.levelValue`），每个级别唯一，用于搜索过滤。
    public let typeValue: Int
    /// 日志正文。
    public let message: String
    /// 附加上下文（JSON 字符串）：文件名、行号、页面名、按钮标题等。
    public let context: String?

    /// 格式化时间字符串（HH:mm:ss.SSS）。
    public var timeString: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    /// 格式化日期时间字符串。
    public var dateTimeString: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

extension BALogEntry {
    /// 从数据库行创建。
    init(id: Int64, timestamp: Double, dateString: String, level: String, typeValue: Int, message: String, context: String?) {
        self.id = id
        self.timestamp = timestamp
        self.dateString = dateString
        self.level = BALogLevel(rawValue: level) ?? .info
        self.typeValue = typeValue
        self.message = message
        self.context = context
    }
}
