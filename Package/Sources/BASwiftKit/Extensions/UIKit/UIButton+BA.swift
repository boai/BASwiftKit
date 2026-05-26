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

    /// 扩大点击区域（按上下左右英寸）
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
}

private final class BAButtonAction {
    private let action: (UIButton) -> Void
    init(_ action: @escaping (UIButton) -> Void) { self.action = action }
    func invoke(_ sender: UIButton) { action(sender) }
}
#endif
