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

    public enum Background {
        case solid(UIColor)
        case gradient(colors: [UIColor], direction: BAGradientView.Direction)
        case transparent
    }

    public var background: Background
    public var tintColor: UIColor
    public var titleColor: UIColor
    public var titleFont: UIFont
    public var largeTitleFont: UIFont
    public var hideBottomLine: Bool

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
        if #available(iOS 15.0, *) {
            navigationBar.compactAppearance = appearance
            navigationBar.compactScrollEdgeAppearance = appearance
        }
        navigationBar.tintColor = style.tintColor
        navigationBar.barTintColor = style.tintColor
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
