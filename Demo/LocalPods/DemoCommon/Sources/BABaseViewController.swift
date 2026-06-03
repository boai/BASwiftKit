//
//  BABaseViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

/// Demo 内通用基类：统一背景、导航栏外观。
open class BABaseViewController: UIViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BAAppTheme.background
        addBackgroundGlow()

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BAAppTheme.background
        appearance.titleTextAttributes = [
            .foregroundColor: BAAppTheme.textPrimary,
            .font: BAAppTheme.titleFont
        ]
        appearance.shadowColor = .clear

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance

        if let nav = navigationController {
            nav.navigationBar.tintColor = BAAppTheme.accent
        }
    }

    private func addBackgroundGlow() {
        let glow = BAGradientView()
        glow.isUserInteractionEnabled = false
        glow.ba_colors = [
            BAAppTheme.accent.withAlphaComponent(0.16),
            BAAppTheme.accentSecondary.withAlphaComponent(0.06),
            BAAppTheme.background.withAlphaComponent(0)
        ]
        glow.ba_direction = .vertical
        view.insertSubview(glow, at: 0)
        glow.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(260)
        }
    }
}
