//
//  BARouteInterceptor.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation

// MARK: - Interceptor Context

/// 路由拦截上下文，携带当前路由的全部信息供拦截器判断。
public struct BARouteContext {
    /// 原始 URL 字符串。
    public let url: String
    /// 匹配到的路由配置。
    public let config: BARouteConfig
    /// URL 解析出的参数字典。
    public let params: [String: Any]
    /// 当前最顶层的 ViewController（UIKit 环境下为实际 VC，否则为 `nil`）。
    ///
    /// 拦截器/Handler 中可按需 `as? UIViewController` 转回具体类型。
    public weak var topViewController: AnyObject?
    /// 当前有效的 UINavigationController（UIKit 环境下为实际 NC，否则为 `nil`）。
    public weak var navigationController: AnyObject?

    /// 创建拦截上下文。
    public init(
        url: String,
        config: BARouteConfig,
        params: [String: Any],
        topViewController: AnyObject?,
        navigationController: AnyObject?
    ) {
        self.url = url
        self.config = config
        self.params = params
        self.topViewController = topViewController
        self.navigationController = navigationController
    }
}

// MARK: - Interceptor Result

/// 拦截器处理结果。
public enum BARouteInterceptorResult {
    /// 放行，继续执行下一个拦截器或路由跳转。
    case `continue`
    /// 拦截通过但修改了上下文（如 URL 重定向、参数注入）。
    /// - Parameter context: 修改后的新上下文。
    case continueWith(BARouteContext)
    /// 阻断，终止路由跳转。
    /// - Parameter reason: 阻断原因（用于日志）。
    case block(String)
    /// 重定向到另一个 URL。
    /// - Parameter url: 目标 URL。
    case redirect(String)
}

// MARK: - Interceptor Protocol

/// 路由拦截器协议。
///
/// 实现该协议即可在每次路由跳转前后插入自定义逻辑：
/// - 登录校验
/// - 埋点上报
/// - 黑白名单过滤
/// - AB 实验路由重定向
/// - 参数注入
///
/// ```swift
/// struct LoginInterceptor: BARouteInterceptor {
///     var name: String { "登录拦截器" }
///     var priority: Int { 100 }
///
///     func shouldOpen(_ context: BARouteContext) -> BARouteInterceptorResult {
///         if UserManager.shared.isLoggedIn { return .continue }
///         return .redirect("/login?redirect=\(context.url)")
///     }
/// }
/// ```
public protocol BARouteInterceptor: AnyObject {
    /// 拦截器唯一名称，用于日志和调试。
    var name: String { get }

    /// 优先级，数值越小越先执行。默认 `0`。
    var priority: Int { get }

    /// 路由执行前回调。
    ///
    /// 返回 `.continue` 放行，`.block("原因")` 阻断，`.redirect("url")` 重定向，`.continueWith(newContext)` 修改上下文。
    ///
    /// - Parameter context: 当前路由上下文。
    /// - Returns: 拦截结果。
    func shouldOpen(_ context: BARouteContext) -> BARouteInterceptorResult

    /// 路由执行完成后回调（无论成功或失败）。
    ///
    /// - Parameters:
    ///   - context: 路由上下文。
    ///   - error: 若执行失败则为对应错误，成功时为 `nil`。
    func didOpen(_ context: BARouteContext, error: BARouteError?)
}

// MARK: - Default Implementations

public extension BARouteInterceptor {
    var priority: Int { 0 }

    func didOpen(_ context: BARouteContext, error: BARouteError?) {
        // 默认空实现，子类按需重写
    }
}

// MARK: - Interceptor Chain

/// 拦截器链：按优先级排序后顺序执行所有拦截器。
final class BARouteInterceptorChain {
    private var interceptors: [BARouteInterceptor] = []

    /// 添加一个拦截器。
    func add(_ interceptor: BARouteInterceptor) {
        interceptors.append(interceptor)
        interceptors.sort { $0.priority < $1.priority }
    }

    /// 移除指定名称的拦截器。
    func remove(name: String) {
        interceptors.removeAll { $0.name == name }
    }

    /// 移除全部拦截器。
    func removeAll() {
        interceptors.removeAll()
    }

    /// 顺序执行所有拦截器的 `shouldOpen`，任一返回非 `.continue` 则立即返回。
    ///
    /// - Parameter context: 初始路由上下文。
    /// - Returns: 最终拦截结果和可能被修改的上下文。
    func execute(_ context: BARouteContext) -> (result: BARouteInterceptorResult, context: BARouteContext) {
        var currentContext = context
        for interceptor in interceptors {
            let result = interceptor.shouldOpen(currentContext)
            switch result {
            case .continue:
                continue
            case .continueWith(let newContext):
                currentContext = newContext
            case .block, .redirect:
                return (result, currentContext)
            }
        }
        return (.continue, currentContext)
    }

    /// 逆序执行所有拦截器的 `didOpen`（后进先回调）。
    func notifyDidOpen(_ context: BARouteContext, error: BARouteError?) {
        for interceptor in interceptors.reversed() {
            interceptor.didOpen(context, error: error)
        }
    }
}
