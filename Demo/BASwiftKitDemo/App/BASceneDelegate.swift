//
//  BASceneDelegate.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

class BASceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = BADemoRootFactory.make()
        window.makeKeyAndVisible()
        self.window = window

        // 注册自定义品牌主题（以便按 id 恢复），并恢复用户上次选择的主题。
        // 窗口已就绪，restore() 会把对应的 overrideUserInterfaceStyle 应用到窗口。
        BAThemeManager.shared.register(BABrandOceanPalette())
        BAThemeManager.shared.restore()
    }
}

// MARK: - 自定义品牌主题示例

/// 「海洋」品牌主题示例。
///
/// 演示自定义主题的低成本接入：只声明 `identifier` 并覆盖少数关心的语义色槽，
/// 其余自动回落到协议默认（系统语义色）。配合 `view.ba_applyTheme { ... }` 绑定，
/// 切换到本主题时被绑定的视图会自动重渲染。
struct BABrandOceanPalette: BAThemePalette {
    let identifier = "ocean"
    let userInterfaceStyle: UIUserInterfaceStyle = .light
    var primary: UIColor { UIColor(ba_hex: "#0A84FF") ?? .systemBlue }
    var accent: UIColor { UIColor(ba_hex: "#30B0C7") ?? .systemTeal }
    var background: UIColor { UIColor(ba_hex: "#EAF4FF") ?? .systemBackground }
    var secondaryBackground: UIColor { UIColor(ba_hex: "#D6EBFF") ?? .secondarySystemBackground }
}
