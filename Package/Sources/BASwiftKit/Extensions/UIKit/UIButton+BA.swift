//
//  UIButton+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBAButtonActionKey: UInt8 = 0

public extension UIButton {

    /// 闭包式点击事件
    func ba_onTap(_ action: @escaping (UIButton) -> Void) {
        objc_setAssociatedObject(self, &kBAButtonActionKey, BAButtonAction(action),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(ba_handleAction(_:)), for: .touchUpInside)
    }

    /// 触发闭包式点击事件。
    @objc private func ba_handleAction(_ sender: UIButton) {
        guard let box = objc_getAssociatedObject(self, &kBAButtonActionKey) as? BAButtonAction else { return }
        box.invoke(sender)
    }

    /// 链式便利构造
    static func ba_make(title: String? = nil,
                        titleColor: UIColor = .white,
                        backgroundColor: UIColor = .systemBlue,
                        font: UIFont = .systemFont(ofSize: 15, weight: .medium),
                        cornerRadius: CGFloat = 8) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(titleColor, for: .normal)
        btn.titleLabel?.font = font
        btn.backgroundColor = backgroundColor
        btn.layer.cornerRadius = cornerRadius
        btn.layer.cornerCurve = .continuous
        btn.layer.masksToBounds = false
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        btn.tintColor = titleColor
        btn.ba_setShadow(color: backgroundColor, opacity: 0.22, radius: 12, offset: CGSize(width: 0, height: 6))
        return btn
    }

    /// 链式设置按钮标题。
    ///
    /// - Parameters:
    ///   - title: 按钮标题。
    ///   - state: 控件状态，默认 `.normal`。
    /// - Returns: 当前按钮实例，便于继续链式调用。
    @discardableResult
    func ba_title(_ title: String?, for state: UIControl.State = .normal) -> Self {
        setTitle(title, for: state)
        return self
    }

    /// 链式设置按钮标题颜色。
    ///
    /// - Parameters:
    ///   - color: 标题颜色。
    ///   - state: 控件状态，默认 `.normal`。
    /// - Returns: 当前按钮实例，便于继续链式调用。
    @discardableResult
    func ba_titleColor(_ color: UIColor, for state: UIControl.State = .normal) -> Self {
        setTitleColor(color, for: state)
        return self
    }

    /// 链式设置按钮标题字体。
    ///
    /// - Parameter font: 标题字体。
    /// - Returns: 当前按钮实例，便于继续链式调用。
    @discardableResult
    func ba_font(_ font: UIFont) -> Self {
        titleLabel?.font = font
        return self
    }

    /// 链式设置按钮背景色。
    ///
    /// - Parameter color: 背景色。
    /// - Returns: 当前按钮实例，便于继续链式调用。
    @discardableResult
    func ba_fillColor(_ color: UIColor) -> Self {
        backgroundColor = color
        return self
    }

    /// 链式设置按钮圆角。
    ///
    /// - Parameter radius: 圆角半径。
    /// - Returns: 当前按钮实例，便于继续链式调用。
    @discardableResult
    func ba_cornerRadius(_ radius: CGFloat) -> Self {
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        return self
    }
}

private final class BAButtonAction {
    private let action: (UIButton) -> Void
    init(_ action: @escaping (UIButton) -> Void) { self.action = action }
    func invoke(_ sender: UIButton) { action(sender) }
}
#endif
