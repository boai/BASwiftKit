//
//  UIStackView+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIStackView {

    /// 链式便利构造
    static func ba_make(axis: NSLayoutConstraint.Axis = .vertical,
                        spacing: CGFloat = 0,
                        alignment: UIStackView.Alignment = .fill,
                        distribution: UIStackView.Distribution = .fill) -> UIStackView {
        let s = UIStackView()
        s.axis = axis
        s.spacing = spacing
        s.alignment = alignment
        s.distribution = distribution
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    /// 批量 addArrangedSubview
    func ba_addArrangedSubviews(_ views: UIView...) {
        views.forEach { addArrangedSubview($0) }
    }

    /// 批量 addArrangedSubview
    func ba_addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }

    /// 移除全部 arranged subview（同时从父视图移除）
    func ba_removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    /// 在指定 view 之后插入新 view
    func ba_insert(_ view: UIView, after target: UIView) {
        guard let idx = arrangedSubviews.firstIndex(of: target) else {
            addArrangedSubview(view)
            return
        }
        insertArrangedSubview(view, at: idx + 1)
    }
}
#endif
