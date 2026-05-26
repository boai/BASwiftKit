//
//  BAWebViewConfiguration.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import WebKit

/// WebView 拦截器协议，用于自定义 URL 请求处理。
///
/// 实现此协议可以对特定 URL 进行拦截，返回自定义响应或阻止加载。
/// 拦截器按数组顺序执行，第一个返回非 `nil` 结果的拦截器生效。
///
/// ```swift
/// struct MyInterceptor: BAWebViewInterceptor {
///     func canHandle(url: URL) -> Bool {
///         url.host == "example.com"
///     }
///
///     func handle(url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
///         // 自定义处理逻辑
///         decisionHandler(.cancel)
///     }
/// }
/// ```
public protocol BAWebViewInterceptor {
    /// 判断该拦截器是否能处理指定 URL。
    /// - Parameter url: 待拦截的 URL。
    /// - Returns: 若能处理返回 `true`。
    func canHandle(url: URL) -> Bool

    /// 拦截并处理指定 URL。
    ///
    /// - Parameters:
    ///   - url: 待拦截的 URL。
    ///   - decisionHandler: 必须调用此闭包通知 WebView 是否继续加载。`.allow` 继续加载，`.cancel` 阻止。
    func handle(url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
}

/// WebView 进度条配置。
///
/// 用于自定义 `BAWebViewController` 顶部进度条的颜色、高度和动画时长。
public struct BAWebViewProgressConfiguration {
    /// 进度条轨道颜色（未完成部分）。
    public var trackTintColor: UIColor
    /// 进度条进度颜色（已完成部分）。
    public var progressTintColor: UIColor
    /// 进度条高度。
    public var height: CGFloat
    /// 进度变化动画时长。
    public var animationDuration: TimeInterval
    /// 加载完成后进度条淡出动画时长。设为 `0` 则不淡出。
    public var fadeOutDuration: TimeInterval

    /// 创建进度条配置。
    ///
    /// - Parameters:
    ///   - trackTintColor: 轨道颜色，默认 `.systemGray5`。
    ///   - progressTintColor: 进度颜色，默认 `.systemBlue`。
    ///   - height: 进度条高度，默认 `2`。
    ///   - animationDuration: 进度变化动画时长，默认 `0.2`。
    ///   - fadeOutDuration: 加载完成后淡出时长，默认 `0.25`。
    public init(trackTintColor: UIColor = .systemGray5,
                progressTintColor: UIColor = .systemBlue,
                height: CGFloat = 2,
                animationDuration: TimeInterval = 0.2,
                fadeOutDuration: TimeInterval = 0.25) {
        self.trackTintColor = trackTintColor
        self.progressTintColor = progressTintColor
        self.height = height
        self.animationDuration = animationDuration
        self.fadeOutDuration = fadeOutDuration
    }

    /// 默认进度条配置。
    public static let `default` = BAWebViewProgressConfiguration()
}

/// WebView 配置对象，用于初始化 `BAWebView` 和 `BAWebViewController`。
///
/// 包含 WebView 的基础行为配置（JavaScript、缓存策略、UserAgent 等）、
/// 拦截器列表、以及进度条外观配置。
public struct BAWebViewConfiguration {
    /// 是否允许 JavaScript 执行。默认 `true`。
    public var allowsJavaScript: Bool
    /// 是否允许内嵌视频自动播放。默认 `false`。
    public var allowsInlineMediaPlayback: Bool
    /// 自定义 User-Agent。`nil` 表示使用系统默认值。
    public var userAgent: String?
    /// 自定义请求头，将在每次加载时附加到请求中。
    public var headers: [String: String]
    /// 拦截器列表，按顺序执行。
    public var interceptors: [BAWebViewInterceptor]
    /// 进度条外观配置。
    public var progressConfiguration: BAWebViewProgressConfiguration
    /// 是否支持下拉刷新。默认 `true`。
    public var pullToRefreshEnabled: Bool
    /// 是否显示底部工具栏（前进/后退/刷新）。默认 `true`。
    public var toolbarEnabled: Bool
    /// 是否自动同步导航栏标题为网页 title。默认 `true`。
    public var titleSyncEnabled: Bool
    /// 自定义超时时间（秒）。默认 `30`。
    public var timeoutInterval: TimeInterval

    /// 创建 WebView 配置。
    ///
    /// - Parameters:
    ///   - allowsJavaScript: 是否允许 JavaScript。默认 `true`。
    ///   - allowsInlineMediaPlayback: 是否允许内嵌视频自动播放。默认 `false`。
    ///   - userAgent: 自定义 User-Agent。
    ///   - headers: 自定义请求头字典。
    ///   - interceptors: URL 拦截器数组。
    ///   - progressConfiguration: 进度条外观配置。
    ///   - pullToRefreshEnabled: 是否支持下拉刷新。
    ///   - toolbarEnabled: 是否显示底部工具栏。
    ///   - titleSyncEnabled: 是否同步网页标题到导航栏。
    ///   - timeoutInterval: 请求超时时间。
    public init(allowsJavaScript: Bool = true,
                allowsInlineMediaPlayback: Bool = false,
                userAgent: String? = nil,
                headers: [String: String] = [:],
                interceptors: [BAWebViewInterceptor] = [],
                progressConfiguration: BAWebViewProgressConfiguration = .default,
                pullToRefreshEnabled: Bool = true,
                toolbarEnabled: Bool = true,
                titleSyncEnabled: Bool = true,
                timeoutInterval: TimeInterval = 30) {
        self.allowsJavaScript = allowsJavaScript
        self.allowsInlineMediaPlayback = allowsInlineMediaPlayback
        self.userAgent = userAgent
        self.headers = headers
        self.interceptors = interceptors
        self.progressConfiguration = progressConfiguration
        self.pullToRefreshEnabled = pullToRefreshEnabled
        self.toolbarEnabled = toolbarEnabled
        self.titleSyncEnabled = titleSyncEnabled
        self.timeoutInterval = timeoutInterval
    }

    /// 默认 WebView 配置。
    public static let `default` = BAWebViewConfiguration()
}
#endif
