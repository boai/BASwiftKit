//
//  BACarouselPageControl.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Indicator Protocol

/// 轮播指示器协议（**自定义指示器的解耦点**）。
///
/// 任意视图实现本协议即可作为 ``BACarouselView`` 的底部指示器，
/// 框架在页数变化、当前页变化时回调更新。内置默认实现见 ``BACarouselPageControl``。
public protocol BACarouselIndicator: AnyObject {
    /// 指示器视图本体（由 `BACarouselView` 添加到底部）。
    var ba_view: UIView { get }
    /// 总页数变化。
    func ba_updateNumberOfPages(_ count: Int)
    /// 当前页变化（取值 `0..<count`）。
    func ba_updateCurrentPage(_ index: Int)
}

// MARK: - Default Page Control

/// 内置默认轮播指示器：一排圆点，当前页高亮（可拉伸为胶囊）。
///
/// 全部样式可配置：颜色、点大小、当前点宽度、间距、是否胶囊高亮。自包含、仅依赖 UIKit。
///
/// ```swift
/// let pc = BACarouselPageControl()
/// pc.currentPageColor = .white
/// pc.pageColor = UIColor.white.withAlphaComponent(0.4)
/// pc.currentDotWidth = 18   // 当前页拉伸成胶囊
/// carousel.indicator = pc
/// ```
public final class BACarouselPageControl: UIView, BACarouselIndicator {

    /// 普通圆点颜色。
    public var pageColor: UIColor = UIColor.white.withAlphaComponent(0.5) { didSet { applyColors() } }
    /// 当前页圆点颜色。
    public var currentPageColor: UIColor = .white { didSet { applyColors() } }
    /// 圆点直径。
    public var dotSize: CGFloat = 7 { didSet { setNeedsLayout() } }
    /// 当前页圆点宽度（大于 `dotSize` 时呈胶囊形）。
    public var currentDotWidth: CGFloat = 7 { didSet { setNeedsLayout() } }
    /// 圆点间距。
    public var dotSpacing: CGFloat = 6 { didSet { setNeedsLayout() } }

    private var dots: [UIView] = []
    private var numberOfPages = 0
    private var currentPage = 0

    public var ba_view: UIView { self }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
    }

    public func ba_updateNumberOfPages(_ count: Int) {
        guard count != numberOfPages else { return }
        numberOfPages = count
        // 重建圆点（页数变化频率极低，重建成本可忽略）。
        dots.forEach { $0.removeFromSuperview() }
        dots = (0..<max(0, count)).map { _ in
            let dot = UIView()
            dot.backgroundColor = pageColor
            addSubview(dot)
            return dot
        }
        if currentPage >= count { currentPage = 0 }
        applyColors()
        setNeedsLayout()
    }

    public func ba_updateCurrentPage(_ index: Int) {
        guard index != currentPage, index >= 0, index < numberOfPages else { return }
        currentPage = index
        applyColors()
        // 当前点可能为胶囊，宽度变化需重新布局（带轻动画更顺滑）。
        UIView.animate(withDuration: 0.25) { self.layoutDots() }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutDots()
    }

    /// 计算并排布所有圆点（整体水平居中）。
    private func layoutDots() {
        guard !dots.isEmpty else { return }
        let totalWidth = dots.indices.reduce(CGFloat(0)) { acc, i in
            acc + (i == currentPage ? currentDotWidth : dotSize) + (i == 0 ? 0 : dotSpacing)
        }
        var x = (bounds.width - totalWidth) / 2
        let y = (bounds.height - dotSize) / 2
        for (i, dot) in dots.enumerated() {
            let width = (i == currentPage) ? currentDotWidth : dotSize
            dot.frame = CGRect(x: x, y: y, width: width, height: dotSize)
            dot.layer.cornerRadius = dotSize / 2
            x += width + dotSpacing
        }
    }

    private func applyColors() {
        for (i, dot) in dots.enumerated() {
            dot.backgroundColor = (i == currentPage) ? currentPageColor : pageColor
        }
    }
}
#endif
