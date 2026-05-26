//
//  UIApplication+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIApplication {

    /// 当前活跃 scene 的 keyWindow（iOS 13+ 多 scene 安全）
    var ba_keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
                ?? connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })
        }
        return windows.first(where: { $0.isKeyWindow })
    }

    /// 当前可见的最顶层 UIViewController（穿透 navigation / tab / present）
    var ba_topViewController: UIViewController? {
        ba_keyWindow?.ba_topViewController
    }
}

public extension UIWindow {

    /// 沿着 rootViewController 一直走到最顶层可见的 VC
    var ba_topViewController: UIViewController? {
        UIApplication.ba_top(from: rootViewController)
    }

    /// 平滑替换 rootViewController（带交叉淡入动画）
    func ba_replaceRootViewController(_ newRoot: UIViewController,
                                      duration: TimeInterval = 0.3,
                                      options: UIView.AnimationOptions = .transitionCrossDissolve,
                                      completion: (() -> Void)? = nil) {
        let snapshot = snapshotView(afterScreenUpdates: true)
        rootViewController = newRoot
        if let snapshot = snapshot {
            newRoot.view.addSubview(snapshot)
            UIView.animate(withDuration: duration, animations: {
                snapshot.layer.opacity = 0
            }, completion: { _ in
                snapshot.removeFromSuperview()
                completion?()
            })
        } else {
            UIView.transition(with: self,
                              duration: duration,
                              options: options,
                              animations: nil,
                              completion: { _ in completion?() })
        }
    }
}

internal extension UIApplication {
    static func ba_top(from vc: UIViewController?) -> UIViewController? {
        if let nav = vc as? UINavigationController {
            return ba_top(from: nav.visibleViewController ?? nav.topViewController)
        }
        if let tab = vc as? UITabBarController {
            return ba_top(from: tab.selectedViewController)
        }
        if let presented = vc?.presentedViewController {
            return ba_top(from: presented)
        }
        return vc
    }
}
#endif
