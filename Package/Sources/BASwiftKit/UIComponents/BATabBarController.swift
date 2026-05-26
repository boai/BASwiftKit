//
//  BATabBarController.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 一个 Tab 项的描述
public struct BATabItem {
    public let title: String
    public let icon: UIImage?
    public let selectedIcon: UIImage?
    public let viewController: UIViewController

    public init(title: String,
                icon: UIImage?,
                selectedIcon: UIImage? = nil,
                viewController: UIViewController) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.viewController = viewController
    }
}

/// 一个简化的 UITabBarController：
/// - 自动给每个子 VC 套 UINavigationController
/// - 选中态着色 + 切换时图标轻微弹跳动画
/// - 支持 `BATabBarItemBadge` 设置数字角标
public final class BATabBarController: UITabBarController, UITabBarControllerDelegate {

    /// 选中色
    public var ba_selectedColor: UIColor = .systemBlue {
        didSet { tabBar.tintColor = ba_selectedColor }
    }

    /// 未选中色
    public var ba_unselectedColor: UIColor = .secondaryLabel {
        didSet { tabBar.unselectedItemTintColor = ba_unselectedColor }
    }

    /// 是否在每个 VC 外面套一层 UINavigationController（默认 true）
    public var ba_embedInNavigation: Bool = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    public func ba_setup(items: [BATabItem]) {
        let controllers: [UIViewController] = items.map { item in
            let vc = item.viewController
            vc.tabBarItem = UITabBarItem(title: item.title,
                                         image: item.icon,
                                         selectedImage: item.selectedIcon ?? item.icon)
            vc.title = item.title
            return ba_embedInNavigation ? UINavigationController(rootViewController: vc) : vc
        }
        viewControllers = controllers
        tabBar.tintColor = ba_selectedColor
        tabBar.unselectedItemTintColor = ba_unselectedColor

        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }

    /// 给指定 index 的 Tab 设置数字角标。0 或负数表示清除
    public func ba_setBadge(_ value: Int, at index: Int) {
        guard let items = tabBar.items, index >= 0, index < items.count else { return }
        if value <= 0 {
            items[index].badgeValue = nil
        } else {
            items[index].badgeValue = value > 99 ? "99+" : "\(value)"
        }
    }

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return }
        let buttons = tabBar.subviews.filter { String(describing: type(of: $0)).contains("UITabBarButton") }
        guard index < buttons.count else { return }
        guard let imageView = buttons[index].subviews.compactMap({ $0 as? UIImageView }).first else { return }
        Self.ba_bounce(view: imageView)
    }

    private static func ba_bounce(view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.scale")
        anim.values = [1.0, 0.85, 1.12, 0.96, 1.0]
        anim.keyTimes = [0, 0.25, 0.55, 0.8, 1.0]
        anim.duration = 0.32
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(anim, forKey: "ba_tabBounce")
    }
}
#endif
