//
//  BAURLContentParser.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Route Source

/// 路由请求来源，用于区分不同入口的跳转行为。
public enum BARouteSource: String {
    /// App 内部调用
    case `internal`
    /// 外部 App 唤起（URL Scheme / Universal Link）
    case externalApp
    /// 远程推送通知
    case remoteNotification
    /// 本地通知
    case localNotification
    /// 深度链接（Deep Link / Firebase Dynamic Link 等）
    case deepLink
    /// 未知来源
    case unknown
}

// MARK: - Route Request

/// 标准化的路由请求模型。
///
/// 将来自不同入口的数据（URL 字符串、通知 payload、Universal Link 等）
/// 统一解析为 `BARouteRequest`，再交由 `BARouter` 执行跳转。
///
/// ```swift
/// // 从 URL 解析
/// if let req = BAURLParser.parse("baswiftkit://demo/animation?tab=ui") {
///     BARouter.shared.open(req)
/// }
///
/// // 从通知 payload 解析
/// if let req = BAURLParser.parse(notificationUserInfo: payload) {
///     BARouter.shared.open(req)
/// }
/// ```
public struct BARouteRequest {

    /// 原始 URL 字符串（含 scheme/host/path/query）。
    public let urlString: String

    /// 路由路径（scheme + host + path 归一化后的部分）。
    /// 例如 `ba://demo/animation` → `/demo/animation`
    public let path: String

    /// 参数字典（路径参数 + Query 参数 合并）。
    public let params: [String: Any]

    /// 请求来源。
    public let source: BARouteSource

    /// 原始来源 payload（通知 userInfo / URL 对象等），供业务方按需提取自定义字段。
    public let rawPayload: Any?

    // MARK: - Init

    /// 创建路由请求。
    ///
    /// - Parameters:
    ///   - urlString: 原始 URL 字符串。
    ///   - path: 解析后的路由路径（如 `/demo/animation`）。
    ///   - params: 参数字典。
    ///   - source: 请求来源，默认 `.internal`。
    ///   - rawPayload: 原始 payload，默认 `nil`。
    public init(
        urlString: String,
        path: String,
        params: [String: Any] = [:],
        source: BARouteSource = .internal,
        rawPayload: Any? = nil
    ) {
        self.urlString = urlString
        self.path = path
        self.params = params
        self.source = source
        self.rawPayload = rawPayload
    }
}

// MARK: - URL Parser

/// 统一 URL 内容解析器。
///
/// 负责将不同来源的原始数据（URL 字符串、通知 payload、Universal Link）
/// 解析为 `BARouteRequest` 标准模型，供 `BARouter` 消费。
///
/// ## 支持的 URL 格式
///
/// | 格式 | 示例 |
/// |------|------|
/// | 完整 Scheme | `baswiftkit://demo/animation?tab=ui` |
/// | 简写路径 | `/demo/animation?tab=ui` |
/// | Universal Link | `https://baswiftkit.example.com/demo/animation` |
/// | 带路径参数 | `/user/detail/123?from=list` |
///
/// ## 支持的 Payload 格式
///
/// 远程推送 / 本地通知的 `userInfo` 中可携带路由键：
///
/// | Key | 说明 |
/// |-----|------|
/// | `ba_route` / `route` | 路由路径，如 `/demo/animation` |
/// | `ba_route_url` / `url` | 完整 URL 字符串 |
/// | `ba_route_params` / `params` | 携带的参数字典 |
public enum BAURLParser {

    // MARK: - Constants

    /// 路由 payload 中可识别的 key 集合。
    public struct Keys {
        /// 路由路径 key 候选列表。
        public static let routeKeys: [String] = ["ba_route", "route", "ba_path", "path"]
        /// 完整 URL key 候选列表。
        public static let urlKeys: [String] = ["ba_route_url", "url", "ba_url"]
        /// 参数 key 候选列表。
        public static let paramsKeys: [String] = ["ba_route_params", "params", "ba_params"]
    }

    /// App 支持的 URL Scheme 集合（用于识别并剥离 scheme 前缀）。
    public static var registeredSchemes: Set<String> = ["baswiftkit", "ba", "baswiftkitdemo"]

    // MARK: - URL 解析

    /// 从 URL 字符串解析路由请求。
    ///
    /// 支持完整 scheme URL 和简写路径两种格式：
    /// ```swift
    /// BAURLParser.parse("baswiftkit://demo/animation?tab=ui")
    /// BAURLParser.parse("/demo/animation?tab=ui")
    /// ```
    ///
    /// - Parameters:
    ///   - urlString: 待解析的 URL 字符串。
    ///   - source: 来源标识，默认 `.internal`。
    /// - Returns: 解析后的路由请求，格式不合法时返回 `nil`。
    public static func parse(_ urlString: String, source: BARouteSource = .internal) -> BARouteRequest? {
        let raw = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        // 1. 尝试按完整 URL 解析
        if let url = URL(string: raw), let scheme = url.scheme,
           registeredSchemes.contains(scheme) || raw.hasPrefix("http") {
            return parseURL(url, rawString: raw, source: source)
        }

        // 2. 按简写路径解析（无 scheme）
        return parseShortPath(raw, source: source)
    }

    /// 从 URL 对象解析路由请求。
    ///
    /// 适用于 `UIApplicationDelegate.open(url:)` 等回调场景。
    ///
    /// - Parameters:
    ///   - url: URL 对象。
    ///   - source: 来源标识，默认 `.externalApp`。
    /// - Returns: 解析后的路由请求。
    public static func parse(_ url: URL, source: BARouteSource = .externalApp) -> BARouteRequest? {
        parseURL(url, rawString: url.absoluteString, source: source)
    }

    // MARK: - 通知 Payload 解析

    /// 从推送通知 `userInfo` 中提取路由请求。
    ///
    /// 通知 payload 格式示例：
    /// ```json
    /// {
    ///   "aps": { "alert": "新消息" },
    ///   "ba_route": "/demo/logger",
    ///   "ba_route_params": { "userId": "123" }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - userInfo: 通知的 `userInfo` 字典。
    ///   - source: 来源标识，默认 `.remoteNotification`。
    /// - Returns: 解析后的路由请求，未携带路由信息时返回 `nil`。
    public static func parse(
        notificationUserInfo userInfo: [AnyHashable: Any],
        source: BARouteSource = .remoteNotification
    ) -> BARouteRequest? {
        // 1. 尝试从 url key 中提取完整 URL
        for key in Keys.urlKeys {
            if let urlStr = userInfo[key] as? String {
                return parse(urlStr, source: source)
            }
        }

        // 2. 尝试从 route key 中提取路径
        var routePath: String?
        for key in Keys.routeKeys {
            if let path = userInfo[key] as? String {
                routePath = path
                break
            }
        }
        guard let routePath = routePath else { return nil }

        // 3. 提取参数
        var params: [String: Any] = [:]
        for key in Keys.paramsKeys {
            if let p = userInfo[key] as? [String: Any] {
                params.merge(p) { _, new in new }
                break
            }
        }
        // 将非保留 key 的 payload 内容也并入 params
        let reservedKeys: Set<String> = ["aps", "ba_route", "route", "ba_path", "path",
                                          "ba_route_url", "url", "ba_url",
                                          "ba_route_params", "params", "ba_params"]
        for (k, v) in userInfo {
            let key = String(describing: k)
            guard !reservedKeys.contains(key) else { continue }
            params[key] = v
        }

        let urlString = "\(routePath)"
        return BARouteRequest(urlString: urlString, path: routePath, params: params, source: source, rawPayload: userInfo)
    }

    // MARK: - Universal Link 解析

    /// 从 Universal Link / 网页 URL 解析路由请求。
    ///
    /// 会自动将 `https://your.domain.com/demo/animation` 映射为 `/demo/animation`。
    ///
    /// - Parameters:
    ///   - url: Universal Link URL 对象。
    ///   - pathPrefixes: 可移除的路径前缀列表（如 `["/app", "/m"]`），默认空。
    ///   - source: 来源标识，默认 `.deepLink`。
    /// - Returns: 解析后的路由请求。
    public static func parse(
        universalLink url: URL,
        pathPrefixes: [String] = [],
        source: BARouteSource = .deepLink
    ) -> BARouteRequest? {
        var path = url.path

        // 移除配置的前缀
        for prefix in pathPrefixes {
            if path.hasPrefix(prefix) {
                path = String(path.dropFirst(prefix.count))
                break
            }
        }

        guard !path.isEmpty else { return nil }

        var params: [String: Any] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                params[item.name] = item.value ?? ""
            }
        }

        return BARouteRequest(
            urlString: url.absoluteString,
            path: path,
            params: params,
            source: source,
            rawPayload: url
        )
    }

    // MARK: - Private Helpers

    private static func parseURL(_ url: URL, rawString: String, source: BARouteSource) -> BARouteRequest? {
        var path = url.path
        if let host = url.host {
            path = "/\(host)\(path)"
        }
        // 归一化：去掉重复斜杠
        path = path.replacingOccurrences(of: "//", with: "/")
        guard !path.isEmpty else { return nil }

        var params: [String: Any] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                params[item.name] = item.value ?? ""
            }
        }

        return BARouteRequest(
            urlString: rawString,
            path: path,
            params: params,
            source: source,
            rawPayload: url
        )
    }

    private static func parseShortPath(_ raw: String, source: BARouteSource) -> BARouteRequest? {
        // 尝试识别 scheme:// 前缀并剥离
        var processed = raw
        for scheme in registeredSchemes {
            let prefix = "\(scheme)://"
            if raw.hasPrefix(prefix) {
                processed = String(raw.dropFirst(prefix.count))
                break
            }
        }

        let parts = processed.split(separator: "?", maxSplits: 1)
        let path = "/\(String(parts.first ?? ""))"
            .replacingOccurrences(of: "//", with: "/")

        var params: [String: Any] = [:]
        if parts.count == 2 {
            let queryString = String(parts[1])
            if let components = URLComponents(string: "app://app?\(queryString)") {
                for item in components.queryItems ?? [] {
                    params[item.name] = item.value ?? ""
                }
            }
        }

        return BARouteRequest(
            urlString: raw,
            path: path,
            params: params,
            source: source,
            rawPayload: nil
        )
    }
}
