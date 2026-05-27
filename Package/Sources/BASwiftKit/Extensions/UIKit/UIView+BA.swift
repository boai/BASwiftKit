//
//  UIView+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIView {

    // MARK: - Frame 便利

    /// frame.origin.x 便捷访问器。
    var ba_x: CGFloat {
        get { frame.origin.x }
        set { var f = frame; f.origin.x = newValue; frame = f }
    }

    /// frame.origin.y 便捷访问器。
    var ba_y: CGFloat {
        get { frame.origin.y }
        set { var f = frame; f.origin.y = newValue; frame = f }
    }

    /// frame.size.width 便捷访问器。
    var ba_width: CGFloat {
        get { frame.size.width }
        set { var f = frame; f.size.width = newValue; frame = f }
    }

    /// frame.size.height 便捷访问器。
    var ba_height: CGFloat {
        get { frame.size.height }
        set { var f = frame; f.size.height = newValue; frame = f }
    }

    // MARK: - 圆角 / 边框 / 阴影

    /// 设置圆角，默认全部
    func ba_setCornerRadius(_ radius: CGFloat,
                            corners: UIRectCorner = .allCorners) {
        if corners == .allCorners {
            layer.cornerRadius = radius
            layer.masksToBounds = true
            return
        }
        // 局部圆角通过 mask 处理
        layoutIfNeeded()
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = path.cgPath
        layer.mask = mask
    }

    /// 设置边框
    func ba_setBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    /// 设置阴影
    func ba_setShadow(color: UIColor = .black,
                      opacity: Float = 0.15,
                      radius: CGFloat = 8,
                      offset: CGSize = CGSize(width: 0, height: 4)) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
    }

    /// 链式设置背景色。
    ///
    /// - Parameter color: 视图背景色。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_backgroundColor(_ color: UIColor) -> Self {
        backgroundColor = color
        return self
    }

    /// 链式设置圆角。
    ///
    /// - Parameters:
    ///   - radius: 圆角半径。
    ///   - masksToBounds: 是否裁剪超出圆角范围的内容，默认 `true`。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_cornerRadius(_ radius: CGFloat, masksToBounds: Bool = true) -> Self {
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.masksToBounds = masksToBounds
        return self
    }

    /// 链式设置边框。
    ///
    /// - Parameters:
    ///   - width: 边框宽度。
    ///   - color: 边框颜色。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_border(width: CGFloat, color: UIColor) -> Self {
        ba_setBorder(width: width, color: color)
        return self
    }

    /// 链式设置阴影。
    ///
    /// - Parameters:
    ///   - color: 阴影颜色。
    ///   - opacity: 阴影透明度。
    ///   - radius: 阴影模糊半径。
    ///   - offset: 阴影偏移量。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_shadow(color: UIColor = .black,
                   opacity: Float = 0.15,
                   radius: CGFloat = 8,
                   offset: CGSize = CGSize(width: 0, height: 4)) -> Self {
        ba_setShadow(color: color, opacity: opacity, radius: radius, offset: offset)
        return self
    }

    /// 链式设置隐藏状态。
    ///
    /// - Parameter hidden: 是否隐藏。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_hidden(_ hidden: Bool) -> Self {
        isHidden = hidden
        return self
    }

    /// 链式设置透明度。
    ///
    /// - Parameter alpha: 透明度，取值通常为 0~1。
    /// - Returns: 当前视图实例，便于继续链式调用。
    @discardableResult
    func ba_alpha(_ alpha: CGFloat) -> Self {
        self.alpha = alpha
        return self
    }

    // MARK: - 快速添加子视图

    /// 批量 addSubview
    func ba_addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    /// 返回当前视图所在的 UIViewController
    var ba_parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController { return vc }
            responder = next
        }
        return nil
    }

    // MARK: - 截图

    /// 把当前视图渲染为 UIImage
    func ba_snapshotImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            layer.render(in: ctx.cgContext)
        }
    }

    // MARK: - 移除全部子视图

    /// 移除当前视图的全部子视图。
    func ba_removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
#endif
