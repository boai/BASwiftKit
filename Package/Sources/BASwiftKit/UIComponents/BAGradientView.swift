//
//  BAGradientView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 自动布局尺寸跟随的线性渐变 View。
public final class BAGradientView: UIView {

    /// 使用 `CAGradientLayer` 作为底层 layer。
    public override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    /// 渐变方向
    public enum Direction {
        case horizontal, vertical, leadingDiagonal, trailingDiagonal

        var points: (start: CGPoint, end: CGPoint) {
            switch self {
            case .horizontal:        return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
            case .vertical:          return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1))
            case .leadingDiagonal:   return (CGPoint(x: 0, y: 0),   CGPoint(x: 1, y: 1))
            case .trailingDiagonal:  return (CGPoint(x: 1, y: 0),   CGPoint(x: 0, y: 1))
            }
        }
    }

    /// 渐变颜色数组，至少传入两个颜色效果最佳。
    public var ba_colors: [UIColor] = [.systemBlue, .systemPurple] {
        didSet { applyColors() }
    }

    /// 渐变方向。
    public var ba_direction: Direction = .leadingDiagonal {
        didSet { applyDirection() }
    }

    /// 渐变位置数组，对应 `CAGradientLayer.locations`。
    public var ba_locations: [NSNumber]? {
        didSet { gradientLayer.locations = ba_locations }
    }

    /// 代码创建渐变视图。
    public override init(frame: CGRect) {
        super.init(frame: frame)
        applyColors()
        applyDirection()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyColors()
        applyDirection()
    }

    private func applyColors() {
        gradientLayer.colors = ba_colors.map { $0.cgColor }
    }

    private func applyDirection() {
        let (s, e) = ba_direction.points
        gradientLayer.startPoint = s
        gradientLayer.endPoint = e
    }
}
#endif
