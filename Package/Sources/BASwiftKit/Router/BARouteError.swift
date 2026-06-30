//
//  BARouteError.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

/// 路由错误类型。
///
/// 统一描述路由解析、跳转、服务发现过程中可能出现的错误。
public enum BARouteError: Error, LocalizedError, Equatable {

    // MARK: - Route Errors

    /// URL 格式不合法。
    /// - Parameter url: 传入的非法 URL 字符串。
    case invalidURL(String)

    /// 未找到匹配的路由。
    /// - Parameter url: 未能匹配的 URL 字符串。
    case routeNotFound(String)

    /// 路由参数解析失败。
    /// - Parameters:
    ///   - url: 原始 URL。
    ///   - reason: 失败原因。
    case parameterError(url: String, reason: String)

    /// 路由跳转被拦截器阻断。
    /// - Parameters:
    ///   - url: 被拦截的 URL。
    ///   - interceptor: 拦截器名称。
    case blocked(url: String, interceptor: String)

    /// 重定向次数超过上限（疑似循环重定向）。
    /// - Parameter url: 触发超限的 URL。
    case tooManyRedirects(String)

    // MARK: - Service Errors

    /// 未找到匹配的服务。
    /// - Parameter type: 请求的协议类型名。
    case serviceNotFound(String)

    /// 服务创建失败。
    /// - Parameters:
    ///   - type: 服务类型名。
    ///   - reason: 失败原因。
    case serviceCreationFailed(type: String, reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "路由 URL 格式不合法: \(url)"
        case .routeNotFound(let url):
            return "未找到匹配的路由: \(url)"
        case .parameterError(let url, let reason):
            return "路由参数解析失败: \(url), 原因: \(reason)"
        case .blocked(let url, let interceptor):
            return "路由跳转被拦截: \(url), 拦截器: \(interceptor)"
        case .tooManyRedirects(let url):
            return "路由重定向次数超过上限（疑似循环重定向）: \(url)"
        case .serviceNotFound(let type):
            return "未找到注册的服务: \(type)"
        case .serviceCreationFailed(let type, let reason):
            return "服务创建失败: \(type), 原因: \(reason)"
        }
    }
}
