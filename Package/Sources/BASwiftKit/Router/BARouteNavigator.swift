//
//  BARouteNavigator.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

#if canImport(UIKit)
import UIKit

// MARK: - Route Navigator

/// 路由导航辅助工具。
///
/// 提供标准的 push / present / root 导航操作，供 `BARouteHandler` 实现中复用。
/// Handler 也可以不依赖本工具，自行实现导航逻辑（例如自定义转场动画）。
///
/// ## 使用方式
///
/// ```swift
/// final class UserDetailRouteHandler: BARouteHandler {
///     func handle(params:, sourceType:, animated:, completion:) {
///         let vc = UserDetailViewController()
///         vc.receiveRouteParams(params)
///         BARouteNavigator.navigate(vc, sourceType: sourceType, animated: animated)
///         completion(nil)
///     }
/// }
/// ```
public enum BARouteNavigator {

    // MARK: - Navigate

    /// 根据 `sourceType` 执行相应的导航操作。
    ///
    /// - Parameters:
    ///   - viewController: 目标页面。
    ///   - sourceType: 导航方式（auto / push / present / root）。
    ///   - animated: 是否带动画。
    ///   - presentCompletion: present 动画完成回调，默认 `nil`。
    /// - Returns: 导航失败时返回 `BARouteError`，成功返回 `nil`。
    @discardableResult
    public static func navigate(
        _ viewController: UIViewController,
        sourceType: BARouteSourceType,
        animated: Bool,
        presentCompletion: (() -> Void)? = nil
    ) -> BARouteError? {
        switch sourceType {
        case .auto:
            if let nav = currentNavigationController {
                nav.pushViewController(viewController, animated: animated)
            } else {
                currentViewController?.present(viewController, animated: animated, completion: presentCompletion)
            }

        case .push:
            guard let nav = currentNavigationController else {
                return BARouteError.parameterError(
                    url: "",
                    reason: "Push 需要当前页面在 UINavigationController 栈中"
                )
            }
            nav.pushViewController(viewController, animated: animated)

        case .present:
            currentViewController?.present(viewController, animated: animated, completion: presentCompletion)

        case .root:
            guard let window = keyWindow else {
                return BARouteError.parameterError(
                    url: "",
                    reason: "无法获取 KeyWindow 设置 RootViewController"
                )
            }
            window.rootViewController = viewController
            window.makeKeyAndVisible()
        }

        return nil
    }

    /// Push 导航（便捷方法）。
    @discardableResult
    public static func push(_ viewController: UIViewController, animated: Bool = true) -> BARouteError? {
        navigate(viewController, sourceType: .push, animated: animated)
    }

    /// Present 导航（便捷方法）。
    @discardableResult
    public static func present(_ viewController: UIViewController, animated: Bool = true) -> BARouteError? {
        navigate(viewController, sourceType: .present, animated: animated)
    }

    // MARK: - ViewController Hierarchy

    /// 当前最顶层的 ViewController。
    public static var currentViewController: UIViewController? {
        guard let root = keyWindow?.rootViewController else { return nil }
        return findTop(from: root)
    }

    /// 当前有效的 UINavigationController。
    public static var currentNavigationController: UINavigationController? {
        currentViewController?.navigationController
    }

    /// 当前 KeyWindow。
    public static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first
    }

    // MARK: - Private

    private static func findTop(from vc: UIViewController) -> UIViewController {
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
#endif
