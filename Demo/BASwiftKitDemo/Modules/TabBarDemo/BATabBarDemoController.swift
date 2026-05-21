//
//  BATabBarDemoController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// 演示 `BATabBarController`：
/// - 三个 Tab，进入时自动 push 在 BATabBarController 上方
/// - 给 "Home" 设了一个 8 的角标，"Profile" 设了 999+
final class BATabBarDemoLauncher {
    static func make() -> UIViewController {
        let tab = BATabBarController()
        tab.ba_selectedColor = BAAppTheme.accent
        tab.ba_unselectedColor = BAAppTheme.textSecondary
        tab.title = "BATabBarController"

        let home = BATabPlaceholderViewController(
            title: "Home",
            tint: BAAppTheme.accent,
            description: "首页占位。\n顶上有 8 个未读角标。"
        )
        let discover = BATabPlaceholderViewController(
            title: "Discover",
            tint: BAAppTheme.success,
            description: "发现页占位。\n切换 Tab 时图标会有弹跳动画。"
        )
        let profile = BATabPlaceholderViewController(
            title: "Profile",
            tint: BAAppTheme.accentSecondary,
            description: "我的页占位。\n角标超 99 会显示 99+。"
        )

        let items: [BATabItem] = [
            BATabItem(title: "Home",
                      icon: UIImage(systemName: "house"),
                      selectedIcon: UIImage(systemName: "house.fill"),
                      viewController: home),
            BATabItem(title: "Discover",
                      icon: UIImage(systemName: "safari"),
                      selectedIcon: UIImage(systemName: "safari.fill"),
                      viewController: discover),
            BATabItem(title: "Profile",
                      icon: UIImage(systemName: "person.crop.circle"),
                      selectedIcon: UIImage(systemName: "person.crop.circle.fill"),
                      viewController: profile)
        ]
        tab.ba_setup(items: items)
        tab.ba_setBadge(8, at: 0)
        tab.ba_setBadge(999, at: 2)
        return tab
    }
}

/// 一个简单占位 VC，仅用于 TabBar Demo
final class BATabPlaceholderViewController: BABaseViewController {

    private let descText: String
    private let tint: UIColor

    init(title: String, tint: UIColor, description: String) {
        self.descText = description
        self.tint = tint
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.card
        card.ba_cornerRadius = BAAppTheme.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let gradient = BAGradientView()
        gradient.ba_colors = [tint, tint.withAlphaComponent(0.7)]
        gradient.ba_direction = .leadingDiagonal
        gradient.layer.cornerRadius = 16
        gradient.layer.masksToBounds = true
        gradient.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        gradient.addSubview(icon)

        let titleLabel = UILabel.ba_make(text: title,
                                         font: .ba_bold(22),
                                         color: BAAppTheme.textPrimary,
                                         alignment: .center)
        let body = UILabel.ba_make(text: descText,
                                   font: .ba_medium(14),
                                   color: BAAppTheme.textSecondary,
                                   alignment: .center,
                                   numberOfLines: 0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false

        card.contentView.ba_addSubviews(gradient, titleLabel, body)
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            gradient.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 24),
            gradient.centerXAnchor.constraint(equalTo: card.contentView.centerXAnchor),
            gradient.widthAnchor.constraint(equalToConstant: 80),
            gradient.heightAnchor.constraint(equalToConstant: 80),

            icon.centerXAnchor.constraint(equalTo: gradient.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: gradient.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.topAnchor.constraint(equalTo: gradient.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -16),

            body.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -24)
        ])
    }
}
