//
//  BANavigationBarStyle.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 一份可复用的 NavigationBar 样式描述。
public struct BANavigationBarStyle {

    /// NavigationBar 背景类型。
    public enum Background {
        /// 单色背景。
        case solid(UIColor)
        /// 渐变背景。
        case gradient(colors: [UIColor], direction: BAGradientView.Direction)
        /// 透明背景。
        case transparent
    }

    /// 导航栏背景。
    public var background: Background
    /// 返回按钮、右侧按钮等交互元素颜色。
    public var tintColor: UIColor
    /// 标题文字颜色。
    public var titleColor: UIColor
    /// 普通标题字体。
    public var titleFont: UIFont
    /// 大标题字体。
    public var largeTitleFont: UIFont
    /// 是否隐藏底部分割线。
    public var hideBottomLine: Bool

    /// 创建导航栏样式描述。
    ///
    /// - Parameters:
    ///   - background: 导航栏背景，默认系统背景色。
    ///   - tintColor: 交互元素颜色。
    ///   - titleColor: 标题颜色。
    ///   - titleFont: 普通标题字体。
    ///   - largeTitleFont: 大标题字体。
    ///   - hideBottomLine: 是否隐藏底部分割线。
    public init(background: Background = .solid(.systemBackground),
                tintColor: UIColor = .label,
                titleColor: UIColor = .label,
                titleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold),
                largeTitleFont: UIFont = .systemFont(ofSize: 28, weight: .bold),
                hideBottomLine: Bool = true) {
        self.background = background
        self.tintColor = tintColor
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.largeTitleFont = largeTitleFont
        self.hideBottomLine = hideBottomLine
    }
}

public extension UINavigationController {

    /// 把一份 BANavigationBarStyle 应用到当前导航栏（standard + scrollEdge + compact）
    func ba_apply(style: BANavigationBarStyle) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        switch style.background {
        case .solid(let color):
            appearance.backgroundColor = color
            appearance.backgroundImage = nil
        case .gradient(let colors, let direction):
            let size = CGSize(width: 1, height: 64)
            appearance.backgroundImage = Self.ba_gradientImage(colors: colors, direction: direction, size: size)
            appearance.backgroundColor = .clear
        case .transparent:
            appearance.configureWithTransparentBackground()
        }

        if style.hideBottomLine {
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
        }

        appearance.titleTextAttributes = [.foregroundColor: style.titleColor, .font: style.titleFont]
        appearance.largeTitleTextAttributes = [.foregroundColor: style.titleColor, .font: style.largeTitleFont]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        // 交互元素颜色由 tintColor 设置即可；删除原先误用的 barTintColor —— 它是"背景着色"
        // 属性，被错误地设成了交互色，且背景已由上面的 appearance 统一控制。
        navigationBar.tintColor = style.tintColor
    }

    private static func ba_gradientImage(colors: [UIColor],
                                         direction: BAGradientView.Direction,
                                         size: CGSize) -> UIImage? {
        let layer = CAGradientLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.colors = colors.map { $0.cgColor }
        let (start, end) = direction.points
        layer.startPoint = start
        layer.endPoint = end
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: ctx)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
#endif
