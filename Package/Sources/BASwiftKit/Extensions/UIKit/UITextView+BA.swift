//
//  UITextView+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBATextViewMaxLengthKey: UInt8 = 0
private var kBATextViewPlaceholderLabelKey: UInt8 = 0
private var kBATextViewObserverKey: UInt8 = 0
private var kBATextViewPlaceholderConstraintsKey: UInt8 = 0

public extension UITextView {

    var ba_maxLength: Int {
        get { (objc_getAssociatedObject(self, &kBATextViewMaxLengthKey) as? Int) ?? 0 }
        set {
            objc_setAssociatedObject(self, &kBATextViewMaxLengthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            ba_installTextObserver()
        }
    }

    var ba_placeholder: String? {
        get { ba_placeholderLabel.text }
        set {
            ba_placeholderLabel.text = newValue
            ba_placeholderLabel.isHidden = !text.isEmpty
            ba_installTextObserver()
        }
    }

    var ba_placeholderColor: UIColor {
        get { ba_placeholderLabel.textColor }
        set { ba_placeholderLabel.textColor = newValue }
    }

    func ba_setTextPadding(_ inset: UIEdgeInsets) {
        textContainerInset = inset
        if let label = objc_getAssociatedObject(self, &kBATextViewPlaceholderLabelKey) as? UILabel {
            ba_layoutPlaceholder(label)
        }
    }

    private var ba_placeholderLabel: UILabel {
        if let label = objc_getAssociatedObject(self, &kBATextViewPlaceholderLabelKey) as? UILabel {
            return label
        }
        let label = UILabel()
        label.textColor = .placeholderText
        label.font = font ?? .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        addSubview(label)
        objc_setAssociatedObject(self, &kBATextViewPlaceholderLabelKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        ba_layoutPlaceholder(label)
        return label
    }

    private func ba_layoutPlaceholder(_ label: UILabel) {
        label.translatesAutoresizingMaskIntoConstraints = false
        if let constraints = objc_getAssociatedObject(self, &kBATextViewPlaceholderConstraintsKey) as? [NSLayoutConstraint] {
            NSLayoutConstraint.deactivate(constraints)
        }
        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left + textContainer.lineFragmentPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(textContainerInset.right + textContainer.lineFragmentPadding))
        ]
        NSLayoutConstraint.activate(constraints)
        objc_setAssociatedObject(self, &kBATextViewPlaceholderConstraintsKey, constraints, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func ba_installTextObserver() {
        if objc_getAssociatedObject(self, &kBATextViewObserverKey) != nil { return }
        let token = NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: self, queue: .main) { [weak self] _ in
            self?.ba_handleTextDidChange()
        }
        objc_setAssociatedObject(self, &kBATextViewObserverKey, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func ba_handleTextDidChange() {
        if ba_maxLength > 0, markedTextRange == nil, text.count > ba_maxLength {
            text = String(text.prefix(ba_maxLength))
        }
        ba_placeholderLabel.isHidden = !text.isEmpty
    }
}
#endif
