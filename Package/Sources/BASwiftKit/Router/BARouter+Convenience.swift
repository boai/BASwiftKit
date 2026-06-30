//
//  BARouter+Convenience.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Convenience Registration

public extension BARouter {

    /// 极简注册 —— 面向「上百组件快速接入」的首选 API。
    ///
    /// 只需提供一个「返回目标 VC」的构造闭包，框架自动完成全部样板工作：
    /// 1. 用解析出的参数构造 `BARouteParams` 交给闭包；
    /// 2. 若目标 VC 遵循 ``BARoutable``，自动调用 `receiveRouteParams(_:)` 注入原始参数；
    /// 3. 设置 `title` 与 `hidesBottomBarWhenPushed`；
    /// 4. 按 `sourceType` 执行导航（push / present / root），并把导航结果回传 `completion`。
    ///
    /// 对比旧写法（需手写 `BAClosureRouteHandler` + 手动 `navigate` + `completion`），
    /// 单条路由从十余行缩减到 1～3 行：
    ///
    /// ```swift
    /// BARouter.shared.register("/demo/ui/animation", title: "动画", sourceType: .push) { _ in
    ///     BAAnimationDemoViewController(viewModel: BAAnimationDemoViewModel())
    /// }
    ///
    /// BARouter.shared.register("/user/detail/:userId", sourceType: .push) { params in
    ///     UserDetailViewController(userId: params.string("userId"))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: URL 匹配模式，支持 `:param` 路径参数与 `*` 通配。
    ///   - title: 目标页标题，非 `nil` 时自动赋给 `viewController.title`。
    ///   - sourceType: 导航方式，默认 `.auto`（有导航栈则 push，否则 present）。
    ///   - animated: 是否带转场动画，默认 `true`。
    ///   - hidesBottomBar: push 时是否隐藏底部 TabBar，默认 `true`。
    ///   - interceptors: 该路由专属拦截器，默认空。
    ///   - builder: 目标 VC 构造闭包。返回 `nil` 视为构造失败，`completion` 收到 `.parameterError`。
    func register(
        _ pattern: String,
        title: String? = nil,
        sourceType: BARouteSourceType = .auto,
        animated: Bool = true,
        hidesBottomBar: Bool = true,
        interceptors: [BARouteInterceptor] = [],
        builder: @escaping (BARouteParams) -> UIViewController?
    ) {
        let handler = BAClosureRouteHandler { params, srcType, anim, completion in
            guard let viewController = builder(BARouteParams(params)) else {
                completion(.parameterError(url: pattern, reason: "目标 VC 构造闭包返回 nil"))
                return
            }
            if let title = title {
                viewController.title = title
            }
            viewController.hidesBottomBarWhenPushed = hidesBottomBar
            if let routable = viewController as? BARoutable {
                routable.receiveRouteParams(params)
            }
            // 把真实导航结果（如 push 缺少导航栈）回传，而非无脑 completion(nil)。
            let navError = BARouteNavigator.navigate(viewController, sourceType: srcType, animated: anim)
            completion(navError)
        }

        register(
            BARouteConfig(
                pattern: pattern,
                handler: handler,
                sourceType: sourceType,
                animated: animated,
                interceptors: interceptors
            )
        )
    }
}
#endif
