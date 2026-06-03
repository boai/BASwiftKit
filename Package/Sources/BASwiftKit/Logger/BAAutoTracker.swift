//
//  BAAutoTracker.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC

/// 自动埋点追踪器。
///
/// 通过 Method Swizzling 自动捕获页面浏览和按钮点击事件，无需业务代码侵入。
///
/// ```swift
/// // AppDelegate 中调用一次即可启用
/// BAAutoTracker.start()
/// ```
public enum BAAutoTracker {

    /// 是否已启用自动埋点。
    public private(set) static var isStarted: Bool = false

    /// 启动自动埋点。
    ///
    /// 调用后会：
    /// - 自动在 UIViewController.viewDidAppear 时记录 `.pageView` 日志
    /// - 自动在 UIControl（UIButton 等）触发 `sendAction:to:forEvent:` 时记录 `.buttonClick` 日志
    ///
    /// Swizzling 只执行一次，重复调用安全。
    public static func start() {
        guard !isStarted else { return }
        isStarted = true
        swizzleViewController()
        swizzleControl()
    }

    // MARK: - ViewController Swizzling

    private static func swizzleViewController() {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.ba_tracked_viewDidAppear(_:))

        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }

        let didAdd = class_addMethod(
            UIViewController.self,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )

        if didAdd {
            class_replaceMethod(
                UIViewController.self,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: - UIControl Swizzling

    private static func swizzleControl() {
        let originalSelector = #selector(UIControl.sendAction(_:to:for:))
        let swizzledSelector = #selector(UIControl.ba_tracked_sendAction(_:to:for:))

        guard let originalMethod = class_getInstanceMethod(UIControl.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIControl.self, swizzledSelector) else { return }

        let didAdd = class_addMethod(
            UIControl.self,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )

        if didAdd {
            class_replaceMethod(
                UIControl.self,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

// MARK: - UIViewController Extension

private extension UIViewController {

    @objc func ba_tracked_viewDidAppear(_ animated: Bool) {
        // 调用原始实现（因为已 swizzle，实际调用的是原始的 viewDidAppear）
        ba_tracked_viewDidAppear(animated)

        // 过滤系统控制器
        let className = String(describing: type(of: self))
        let ignoredPrefixes = ["UI", "_UI", "AB", "EK", "MF", "CN", "PK", "QL", "SFSafari"]
        guard !ignoredPrefixes.contains(where: { className.hasPrefix($0) }) else { return }
        guard !(self is UINavigationController),
              !(self is UITabBarController),
              !(self is UIAlertController),
              !(self is UISearchController) else { return }

        BALogManager.shared.logPageView(page: className, title: title)
    }
}

// MARK: - UIControl Extension

private extension UIControl {

    @objc func ba_tracked_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        // 调用原始实现
        ba_tracked_sendAction(action, to: target, for: event)

        // 只记录 touchUpInside 事件（按钮点击）
        guard event?.type == .touches, event?.subtype == .none else { return }

        // 获取按钮标题
        var title: String?
        if let button = self as? UIButton {
            title = button.currentTitle
                ?? button.title(for: .normal)
                ?? button.accessibilityLabel
        }
        let label = title ?? accessibilityLabel ?? "unknown"

        // 获取所在页面
        var page: String?
        if let responder = findViewController() {
            page = String(describing: type(of: responder))
        }

        BALogManager.shared.logButtonClick(buttonTitle: label, page: page)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}
#endif
