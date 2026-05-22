//
//  BABaseViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// Demo 内通用基类：统一背景、导航栏外观。
class BABaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BAAppTheme.background

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
}
