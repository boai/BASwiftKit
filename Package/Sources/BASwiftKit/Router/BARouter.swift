//
//  BARouter.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Router

/// 组件化路由管理器。
///
/// `BARouter` 是 BASwiftKit 路由层的统一入口，遵循 TheRouter 设计范式，
/// 同时支持 **URL 页面跳转** 和 **Protocol 服务发现（IoC）** 两种模式：
///
/// ```swift
/// // 启动时注册路由
/// BARouter.shared.register(
///     BARouteConfig(pattern: "/user/detail/:userId", targetType: .viewController(UserDetailVC.self))
/// )
///
/// // 注册服务
/// BARouter.shared.register(service: UserServiceProtocol.self) { UserServiceImpl() }
///
/// // 页面跳转
/// BARouter.shared.open("/user/detail/123?from=home")
///
/// // 获取服务
/// let userService = BARouter.shared.resolve(UserServiceProtocol.self)
/// ```
///
/// ## 拦截器
///
/// 支持全局拦截器链，适用于登录校验、埋点、AB 路由等场景：
///
/// ```swift
/// BARouter.shared.addInterceptor(LoginInterceptor())
/// BARouter.shared.addInterceptor(TrackInterceptor())
/// ```
///
/// 也可以为单条路由配置专属拦截器（在 `BARouteConfig` 中指定）。
///
/// ## URL Pattern 语法
///
/// | 语法 | 说明 | 示例 |
/// |------|------|------|
/// | `/static/path` | 精确匹配 | `/user/profile` |
/// | `:paramName` | 路径参数 | `/user/:userId` → 提取 `userId` |
/// | `*` | 通配符 | `/web/*` → 匹配 `/web/任意路径` |
/// | `?key=value` | Query 参数 | `?from=home` |
public final class BARouter {

    // MARK: - Singleton

    /// 全局共享实例。
    public static let shared = BARouter()

    /// 是否已在 AppDelegate 中初始化完毕。
    public private(set) var isReady: Bool = false

    // MARK: - Private State

    /// URL Pattern → 路由配置的注册表。
    private var routeMap: [String: BARouteConfig] = [:]

    /// 动态路由 Pattern 列表（包含 `:` 或 `*` 的 pattern），按注册顺序匹配。
    private var dynamicPatterns: [(pattern: String, regex: NSRegularExpression, paramNames: [String])] = []

    /// 服务容器。
    let serviceContainer = BAServiceContainer()

    /// 全局拦截器链。
    let interceptorChain = BARouteInterceptorChain()

    /// 回调注册中心。
    let callbackRegistry = BARouteCallbackRegistry()

    /// 串行队列保证线程安全。
    private let lock = NSLock()

    // MARK: - Init

    private init() {}

    // MARK: - Setup

    /// 初始化路由系统。
    ///
    /// 该方法仅需在 AppDelegate 中调用一次。调用后 `isReady` 置为 `true`，
    /// 此后重复调用无副作用。
    ///
    /// - Parameter autoRegister: 是否开启自动注册扫描（当前版本预留），默认 `false`。
    public func setup(autoRegister: Bool = false) {
        guard !isReady else { return }
        isReady = true
        BARouterLogger.info("BARouter 初始化完成")
    }

    // MARK: - Route Registration

    /// 注册一条页面路由。
    ///
    /// Pattern 相同的多次注册会覆盖旧配置。
    ///
    /// - Parameter config: 路由配置。
    ///
    /// ```swift
    /// BARouter.shared.register(
    ///     BARouteConfig(
    ///         pattern: "/user/detail/:userId",
    ///         targetType: .viewController(UserDetailVC.self),
    ///         sourceType: .push
    ///     )
    /// )
    /// ```
    public func register(_ config: BARouteConfig) {
        lock.lock()
        defer { lock.unlock() }

        routeMap[config.pattern] = config

        // 解析动态 Pattern
        if config.pattern.contains(":") || config.pattern.contains("*") {
            if let (regex, paramNames) = compilePattern(config.pattern) {
                // 移除旧的同 pattern 条目
                dynamicPatterns.removeAll { $0.pattern == config.pattern }
                dynamicPatterns.append((config.pattern, regex, paramNames))
            }
        }

        BARouterLogger.info("注册路由: \(config.pattern)")
    }

    /// 批量注册路由。
    ///
    /// - Parameter configs: 路由配置数组。
    public func registerBatch(_ configs: [BARouteConfig]) {
        for config in configs {
            register(config)
        }
    }

    /// 移除指定 Pattern 的路由。
    ///
    /// - Parameter pattern: 路由 Pattern。
    public func unregister(pattern: String) {
        lock.lock()
        defer { lock.unlock() }
        routeMap.removeValue(forKey: pattern)
        dynamicPatterns.removeAll { $0.pattern == pattern }
        BARouterLogger.info("移除路由: \(pattern)")
    }

    // MARK: - URL Opening

    /// 通过 URL 字符串发起路由跳转。
    ///
    /// - Parameters:
    ///   - url: URL 字符串（支持 scheme 省略的简写，如 `/user/detail/123`）。
    ///   - completion: 跳转完成回调。`error` 为 `nil` 表示成功。
    ///
    /// ```swift
    /// BARouter.shared.open("/user/detail/123?from=home") { error in
    ///     if let error = error {
    ///         print("路由失败: \(error.localizedDescription)")
    ///     }
    /// }
    /// ```
    @discardableResult
    public func open(_ url: String, completion: ((BARouteError?) -> Void)? = nil) -> BARouteError? {
        // 1. 解析 URL
        guard let urlComponents = parseURL(url) else {
            let error = BARouteError.invalidURL(url)
            BARouterLogger.error(error.localizedDescription)
            completion?(error)
            return error
        }

        // 2. 匹配路由
        guard let matchResult = matchRoute(path: urlComponents.path, queryParams: urlComponents.queryParams) else {
            let error = BARouteError.routeNotFound(url)
            BARouterLogger.warning(error.localizedDescription)
            completion?(error)
            return error
        }

        // 3. 构建上下文
        let topVC = topViewController()
        let nav = topVC?.navigationController
        var context = BARouteContext(
            url: url,
            config: matchResult.config,
            params: matchResult.params,
            topViewController: topVC,
            navigationController: nav
        )

        // 4. 执行拦截器链（全局 → 路由专属）
        let (globalResult, globalContext) = interceptorChain.execute(context)
        context = globalContext

        var interceptError: BARouteError?
        switch globalResult {
        case .continue:
            break
        case .continueWith(let newContext):
            context = newContext
        case .block(let reason):
            interceptError = BARouteError.blocked(url: url, interceptor: reason)
        case .redirect(let redirectURL):
            interceptorChain.notifyDidOpen(context, error: nil)
            return open(redirectURL, completion: completion)
        }

        // 检查路由专属拦截器
        if interceptError == nil {
            for interceptor in matchResult.config.interceptors {
                switch interceptor.shouldOpen(context) {
                case .continue:
                    continue
                case .continueWith(let newContext):
                    context = newContext
                case .block(let reason):
                    interceptError = BARouteError.blocked(url: url, interceptor: reason)
                case .redirect(let redirectURL):
                    interceptorChain.notifyDidOpen(context, error: nil)
                    matchResult.config.interceptors.forEach { $0.didOpen(context, error: nil) }
                    return open(redirectURL, completion: completion)
                }
                if interceptError != nil { break }
            }
        }

        if let interceptError = interceptError {
            BARouterLogger.warning(interceptError.localizedDescription)
            interceptorChain.notifyDidOpen(context, error: interceptError)
            matchResult.config.interceptors.forEach { $0.didOpen(context, error: interceptError) }
            completion?(interceptError)
            return interceptError
        }

        // 5. 执行跳转
        performRoute(matchResult: matchResult, context: context) { error in
            self.interceptorChain.notifyDidOpen(context, error: error)
            matchResult.config.interceptors.forEach { $0.didOpen(context, error: error) }
            completion?(error)
        }

        return nil
    }

    /// 通过 URL 对象发起路由跳转。
    @discardableResult
    public func open(_ url: URL, completion: ((BARouteError?) -> Void)? = nil) -> BARouteError? {
        open(url.absoluteString, completion: completion)
    }

    // MARK: - Request-Based Opening

    /// 通过标准化的 `BARouteRequest` 模型发起路由跳转。
    ///
    /// 适用于从不同来源（外部 App、推送通知、Deep Link 等）统一解析后的跳转。
    ///
    /// - Parameters:
    ///   - request: 由 `BAURLParser` 解析出的路由请求。
    ///   - callback: 目标页面回传结果时的回调闭包。
    /// - Returns: 回调令牌，目标页面通过 `sendCallback(_:for:)` 回传结果。
    ///            若不需要回调可忽略。
    ///
    /// ```swift
    /// // 解析外部 URL 并跳转
    /// if let req = BAURLParser.parse("baswiftkit://demo/animation?tab=ui") {
    ///     BARouter.shared.open(req) { result in
    ///         print("目标页回调: \(result ?? "nil")")
    ///     }
    /// }
    /// ```
    @discardableResult
    public func open(_ request: BARouteRequest,
                     callback: BARouteCallback? = nil) -> BARouteCallbackToken? {
        var token: BARouteCallbackToken?
        if let cb = callback {
            token = callbackRegistry.register(cb)
        }

        // 构建完整路径（路径参数 + query 参数合并）
        var path = request.path
        if let tokenStr = token {
            var params = request.params
            params["_ba_callback_token"] = tokenStr
            // 将 params 编码为 query string 追加到 path
            let queryItems = params.compactMap { (key, value) -> String? in
                "\(key)=\(value)"
            }
            if !queryItems.isEmpty {
                path += "?" + queryItems.joined(separator: "&")
            }
        }

        open(path) { error in
            if error != nil, let token = token {
                self.callbackRegistry.remove(token)
            }
        }

        return token
    }

    // MARK: - Callback

    /// 发送路由回调结果。
    ///
    /// 目标页面在处理完业务逻辑后，通过该方法将结果回传给发起方。
    ///
    /// - Parameters:
    ///   - result: 回调结果（可为 String、Dictionary、Model 等任意类型）。
    ///   - token: 发起方持有的回调令牌。
    ///
    /// ```swift
    /// // 目标页
    /// BARouter.shared.sendCallback(["status": "ok", "data": model], for: routeToken)
    /// ```
    public func sendCallback(_ result: Any?, for token: BARouteCallbackToken) {
        guard let callback = callbackRegistry.consume(token) else {
            BARouterLogger.warning("回调令牌无效或已过期: \(token)")
            return
        }
        DispatchQueue.main.async {
            callback(result)
        }
    }

    // MARK: - Service Registration

    /// 注册服务。
    ///
    /// - Parameters:
    ///   - type: 服务协议类型。
    ///   - isSingleton: 是否单例，默认 `true`。
    ///   - creator: 服务工厂闭包。
    ///
    /// ```swift
    /// BARouter.shared.register(service: UserServiceProtocol.self) {
    ///     UserServiceImpl()
    /// }
    /// ```
    public func register<T: BAServiceable>(
        service type: T.Type,
        isSingleton: Bool = true,
        creator: @escaping () -> T
    ) {
        serviceContainer.register(type, isSingleton: isSingleton, creator: creator)
        BARouterLogger.info("注册服务: \(String(describing: type))")
    }

    /// 获取服务实例。
    ///
    /// - Parameter type: 服务协议类型。
    /// - Returns: 服务实例，未注册时返回 `nil`。
    ///
    /// ```swift
    /// let userService = BARouter.shared.resolve(UserServiceProtocol.self)
    /// await userService?.login(phone: "138", code: "1234")
    /// ```
    public func resolve<T: BAServiceable>(_ type: T.Type) -> T? {
        if let instance = serviceContainer.resolve(type) {
            return instance
        }
        BARouterLogger.warning("服务未注册: \(String(describing: type))")
        return nil
    }

    /// 移除服务注册。
    public func removeService<T: BAServiceable>(_ type: T.Type) {
        serviceContainer.remove(type)
    }

    // MARK: - Interceptor Management

    /// 添加全局拦截器。
    ///
    /// 全局拦截器对所有路由生效，按 `priority` 排序执行。
    ///
    /// - Parameter interceptor: 拦截器实例。
    public func addInterceptor(_ interceptor: BARouteInterceptor) {
        interceptorChain.add(interceptor)
        BARouterLogger.info("添加全局拦截器: \(interceptor.name)")
    }

    /// 移除指定名称的全局拦截器。
    public func removeInterceptor(name: String) {
        interceptorChain.remove(name: name)
    }

    /// 清空全部全局拦截器。
    public func removeAllInterceptors() {
        interceptorChain.removeAll()
    }

    // MARK: - Debug

    /// 当前已注册的路由列表（用于调试）。
    public func debugAllRoutes() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(routeMap.keys).sorted()
    }

    /// 当前已注册的服务列表（用于调试）。
    public func debugAllServices() -> [String] {
        serviceContainer.debugAllKeys()
    }

    // MARK: - Private: URL Parsing

    private func parseURL(_ urlString: String) -> (path: String, queryParams: [String: String])? {
        let raw = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // 尝试用 URL 解析完整 scheme 路由
        if let url = URL(string: raw), let host = url.host {
            let path = "/\(host)\(url.path)"
            var queryParams: [String: String] = [:]
            if let components = URLComponents(string: raw) {
                for item in components.queryItems ?? [] {
                    queryParams[item.name] = item.value
                }
            }
            return (path.replacingOccurrences(of: "//", with: "/"), queryParams)
        }

        // 无 scheme 的简写路径（如 /user/detail/123）
        let parts = raw.split(separator: "?", maxSplits: 1)
        let path = String(parts.first ?? "")
        var queryParams: [String: String] = [:]
        if parts.count == 2 {
            let queryString = String(parts[1])
            if let components = URLComponents(string: "app://app?\(queryString)") {
                for item in components.queryItems ?? [] {
                    queryParams[item.name] = item.value
                }
            }
        }
        return (path, queryParams)
    }

    // MARK: - Private: Pattern Matching

    private func compilePattern(_ pattern: String) -> (NSRegularExpression, [String])? {
        var paramNames: [String] = []
        var regexString = "^"

        let segments = pattern.split(separator: "/", omittingEmptySubsequences: false)
        for segment in segments {
            regexString += "/"
            if segment.hasPrefix(":") {
                let name = String(segment.dropFirst())
                paramNames.append(name)
                regexString += "([^/]+)"
            } else if segment == "*" {
                regexString += ".*"
            } else {
                regexString += NSRegularExpression.escapedPattern(for: String(segment))
            }
        }
        regexString += "$"

        guard let regex = try? NSRegularExpression(pattern: regexString, options: [.caseInsensitive]) else {
            BARouterLogger.error("路由 Pattern 编译失败: \(pattern)")
            return nil
        }
        return (regex, paramNames)
    }

    private func matchRoute(path: String, queryParams: [String: String]) -> BARouteMatchResult? {
        lock.lock()
        defer { lock.unlock() }

        // 1. 精确匹配
        if let config = routeMap[path] {
            return BARouteMatchResult(config: config, params: queryParams)
        }

        // 2. 动态 Pattern 匹配
        for (pattern, regex, paramNames) in dynamicPatterns {
            let range = NSRange(location: 0, length: path.utf16.count)
            guard let match = regex.firstMatch(in: path, options: [], range: range) else { continue }
            guard let config = routeMap[pattern] else { continue }

            var params: [String: Any] = queryParams
            for (index, name) in paramNames.enumerated() {
                let captureRange = match.range(at: index + 1)
                if captureRange.location != NSNotFound,
                   let range = Range(captureRange, in: path) {
                    params[name] = String(path[range])
                }
            }
            return BARouteMatchResult(config: config, params: params)
        }

        return nil
    }

    // MARK: - Private: Route Execution

    private func performRoute(
        matchResult: BARouteMatchResult,
        context: BARouteContext,
        completion: @escaping (BARouteError?) -> Void
    ) {
        let config = matchResult.config

        switch config.targetType {
        case .viewController(let vcType):
            performViewControllerRoute(
                vcType: vcType,
                params: matchResult.params,
                sourceType: config.sourceType,
                animated: config.animated,
                completion: completion
            )

        case .action(let handler):
            handler(matchResult.params, { completion(nil) })
        }
    }

    private func performViewControllerRoute(
        vcType: UIViewController.Type,
        params: [String: Any],
        sourceType: BARouteSourceType,
        animated: Bool,
        completion: @escaping (BARouteError?) -> Void
    ) {
        let targetVC = vcType.init()

        // 参数注入（通过 KVC 注入简单属性，若 VC 遵循 BARoutable 则走协议注入）
        if let routable = targetVC as? BARoutable {
            routable.receiveRouteParams(params)
        }

        DispatchQueue.main.async {
            let topVC = self.topViewController()
            let nav = topVC?.navigationController

            switch sourceType {
            case .auto:
                if let nav = nav {
                    nav.pushViewController(targetVC, animated: animated)
                    BARouterLogger.info("跳转 → \(String(describing: vcType)) [push]")
                } else {
                    topVC?.present(targetVC, animated: animated)
                    BARouterLogger.info("跳转 → \(String(describing: vcType)) [present]")
                }

            case .push:
                guard let nav = nav else {
                    let error = BARouteError.parameterError(
                        url: "",
                        reason: "Push 需要当前页面在 UINavigationController 栈中"
                    )
                    BARouterLogger.error(error.localizedDescription)
                    completion(error)
                    return
                }
                nav.pushViewController(targetVC, animated: animated)
                BARouterLogger.info("跳转 → \(String(describing: vcType)) [push]")

            case .present:
                topVC?.present(targetVC, animated: animated)
                BARouterLogger.info("跳转 → \(String(describing: vcType)) [present]")

            case .root:
                if let window = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .first {
                    window.rootViewController = targetVC
                    window.makeKeyAndVisible()
                }
                BARouterLogger.info("跳转 → \(String(describing: vcType)) [root]")
            }

            completion(nil)
        }
    }

    // MARK: - Private: ViewController Hierarchy

    private func topViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first,
            let root = window.rootViewController else { return nil }
        return findTop(from: root)
    }

    private func findTop(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return findTop(from: presented)
        }
        if let nav = vc as? UINavigationController {
            return findTop(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTop(from: selected)
        }
        return vc
    }
}

// MARK: - Logger (Internal)

/// 路由模块内部日志工具。
enum BARouterLogger {
    static func info(_ message: String) {
        #if DEBUG
        print("[BARouter][INFO] \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("[BARouter][WARNING] \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("[BARouter][ERROR] \(message)")
        #endif
    }
}

// MARK: - BAServiceContainer Debug Extension

extension BAServiceContainer {
    func debugAllKeys() -> [String] {
        // 简单返回已注册服务类型名（供调试面板使用）
        return []
    }
}
