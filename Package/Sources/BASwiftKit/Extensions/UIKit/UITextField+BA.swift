//
//  UITextField+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBATextFieldMaxLengthKey: UInt8 = 0

public extension UITextField {

    /// 占位文字颜色
    var ba_placeholderColor: UIColor? {
        get {
            guard let attr = attributedPlaceholder,
                  attr.length > 0 else { return nil }
            return attr.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        }
        set {
            let text = placeholder ?? attributedPlaceholder?.string ?? ""
            guard let color = newValue else {
                attributedPlaceholder = NSAttributedString(string: text)
                return
            }
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: font ?? UIFont.systemFont(ofSize: 14)
            ]
            attributedPlaceholder = NSAttributedString(string: text, attributes: attrs)
        }
    }

    /// 限制最大输入长度（中文按 1 个字符计）
    /// 设为 0 表示不限制
    var ba_maxLength: Int {
        get { (objc_getAssociatedObject(self, &kBATextFieldMaxLengthKey) as? Int) ?? 0 }
        set {
            objc_setAssociatedObject(self, &kBATextFieldMaxLengthKey, newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            removeTarget(self, action: #selector(ba_enforceMaxLength), for: .editingChanged)
            if newValue > 0 {
                addTarget(self, action: #selector(ba_enforceMaxLength), for: .editingChanged)
            }
        }
    }

    @objc private func ba_enforceMaxLength() {
        let max = ba_maxLength
        guard max > 0, let text = text, text.count > max else { return }
        // 处理候选词（marked text）时不截断，避免中文/日文输入异常
        if markedTextRange != nil { return }
        self.text = String(text.prefix(max))
    }

    /// 切换 isSecureTextEntry，并保留光标位置
    func ba_toggleSecureEntry() {
        let wasFirst = isFirstResponder
        let cached = text
        isSecureTextEntry.toggle()
        if wasFirst {
            _ = becomeFirstResponder()
        }
        // 切换 isSecureTextEntry 后系统会清掉 text，需要还原
        if let cached = cached, text != cached {
            text = cached
        }
    }

    /// 左侧 padding（清除现有 leftView 后设置）
    func ba_leftPadding(_ padding: CGFloat) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 1))
        leftView = view
        leftViewMode = .always
    }
}
#endif
