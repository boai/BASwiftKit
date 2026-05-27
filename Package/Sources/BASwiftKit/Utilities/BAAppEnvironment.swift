//
//  BAAppEnvironment.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit

/// iOS 开发常用运行环境变量。
///
/// Swift 不推荐继续使用宏定义，这里用静态属性提供更安全的等价能力，覆盖屏幕宽高、KeyWindow、当前控制器、
/// SafeArea、StatusBar、NavigationBar、TabBar 等常用值。所有值都会在访问时实时读取，适配旋转、多 Scene 和安全区变化。
public enum BAAppEnvironment {

    // MARK: - Screen

    /// 主屏幕 bounds，单位为 point。
    public static var ba_screenBounds: CGRect { UIScreen.main.bounds }
    /// 主屏幕尺寸，单位为 point。
    public static var ba_screenSize: CGSize { ba_screenBounds.size }
    /// 主屏幕宽度，单位为 point。
    public static var ba_screenWidth: CGFloat { ba_screenSize.width }
    /// 主屏幕高度，单位为 point。
    public static var ba_screenHeight: CGFloat { ba_screenSize.height }
    /// 主屏幕缩放倍率，例如 2.0、3.0。
    public static var ba_screenScale: CGFloat { UIScreen.main.scale }
    /// 屏幕像素宽度。
    public static var ba_screenPixelWidth: CGFloat { ba_screenWidth * ba_screenScale }
    /// 屏幕像素高度。
    public static var ba_screenPixelHeight: CGFloat { ba_screenHeight * ba_screenScale }
    /// 当前界面是否竖屏。
    public static var ba_isPortrait: Bool { ba_screenHeight >= ba_screenWidth }
    /// 当前界面是否横屏。
    public static var ba_isLandscape: Bool { ba_screenWidth > ba_screenHeight }

    // MARK: - Window / ViewController

    /// 当前前台活跃 Scene 的 KeyWindow。
    public static var ba_keyWindow: UIWindow? { UIApplication.shared.ba_keyWindow }
    /// KeyWindow 的根控制器。
    public static var ba_rootViewController: UIViewController? { ba_keyWindow?.rootViewController }
    /// 当前可见的最顶层控制器，会穿透 UINavigationController、UITabBarController 和 presentedViewController。
    public static var ba_currentViewController: UIViewController? { UIApplication.shared.ba_topViewController }
    /// 当前 KeyWindow 的 bounds。
    public static var ba_windowBounds: CGRect { ba_keyWindow?.bounds ?? ba_screenBounds }
    /// 当前 KeyWindow 的宽度，取不到窗口时回退到屏幕宽度。
    public static var ba_windowWidth: CGFloat { ba_windowBounds.width }
    /// 当前 KeyWindow 的高度，取不到窗口时回退到屏幕高度。
    public static var ba_windowHeight: CGFloat { ba_windowBounds.height }

    // MARK: - Safe Area

    /// 当前 KeyWindow 的安全区。不在窗口层级或启动早期取不到窗口时返回 `.zero`。
    public static var ba_safeAreaInsets: UIEdgeInsets { ba_keyWindow?.safeAreaInsets ?? .zero }
    /// 顶部安全区高度，刘海屏、灵动岛机型通常大于 20。
    public static var ba_safeAreaTop: CGFloat { ba_safeAreaInsets.top }
    /// 底部安全区高度，全面屏底部 Home Indicator 区域通常大于 0。
    public static var ba_safeAreaBottom: CGFloat { ba_safeAreaInsets.bottom }
    /// 左侧安全区宽度。
    public static var ba_safeAreaLeft: CGFloat { ba_safeAreaInsets.left }
    /// 右侧安全区宽度。
    public static var ba_safeAreaRight: CGFloat { ba_safeAreaInsets.right }
    /// 是否存在明显安全区顶部，常用于粗略判断刘海屏或灵动岛。
    public static var ba_hasTopSafeArea: Bool { ba_safeAreaTop > 20 }
    /// 是否存在底部 Home Indicator 安全区。
    public static var ba_hasBottomSafeArea: Bool { ba_safeAreaBottom > 0 }

    // MARK: - System Bars

    /// 状态栏高度。iOS 13+ 从 active UIWindowScene 读取，取不到时回退到顶部安全区。
    public static var ba_statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
            return activeScene?.statusBarManager?.statusBarFrame.height ?? ba_safeAreaTop
        }
        return UIApplication.shared.statusBarFrame.height
    }

    /// 系统导航栏默认高度，未包含状态栏。
    public static var ba_navigationBarHeight: CGFloat { 44 }
    /// 顶部导航区域高度，等于状态栏高度 + 导航栏高度。
    public static var ba_navigationFullHeight: CGFloat { ba_statusBarHeight + ba_navigationBarHeight }
    /// 系统 TabBar 默认高度，未包含底部安全区。
    public static var ba_tabBarHeight: CGFloat { 49 }
    /// 底部 TabBar 区域高度，等于 TabBar 高度 + 安全区底部。
    public static var ba_tabBarFullHeight: CGFloat { ba_tabBarHeight + ba_safeAreaBottom }

    // MARK: - Layout Helpers

    /// 按设计稿宽度等比计算当前屏幕宽度下的值。
    ///
    /// - Parameters:
    ///   - value: 设计稿上的尺寸。
    ///   - designWidth: 设计稿宽度，默认 375。
    /// - Returns: 等比换算后的尺寸。
    public static func ba_scaleWidth(_ value: CGFloat, designWidth: CGFloat = 375) -> CGFloat {
        guard designWidth > 0 else { return value }
        return value * ba_screenWidth / designWidth
    }

    /// 按设计稿高度等比计算当前屏幕高度下的值。
    ///
    /// - Parameters:
    ///   - value: 设计稿上的尺寸。
    ///   - designHeight: 设计稿高度，默认 812。
    /// - Returns: 等比换算后的尺寸。
    public static func ba_scaleHeight(_ value: CGFloat, designHeight: CGFloat = 812) -> CGFloat {
        guard designHeight > 0 else { return value }
        return value * ba_screenHeight / designHeight
    }
}
#endif
