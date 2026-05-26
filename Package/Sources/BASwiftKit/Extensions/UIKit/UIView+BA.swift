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

    var ba_x: CGFloat {
        get { frame.origin.x }
        set { var f = frame; f.origin.x = newValue; frame = f }
    }

    var ba_y: CGFloat {
        get { frame.origin.y }
        set { var f = frame; f.origin.y = newValue; frame = f }
    }

    var ba_width: CGFloat {
        get { frame.size.width }
        set { var f = frame; f.size.width = newValue; frame = f }
    }

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

    func ba_removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
#endif
