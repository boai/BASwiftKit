//
//  UILabel+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UILabel {

    /// 链式便利构造
    static func ba_make(text: String? = nil,
                        font: UIFont = .systemFont(ofSize: 14),
                        color: UIColor = .label,
                        alignment: NSTextAlignment = .natural,
                        numberOfLines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        return label
    }

    /// 设置行间距（保留当前 text）
    func ba_setLineSpacing(_ spacing: CGFloat) {
        guard let raw = text, !raw.isEmpty else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = spacing
        paragraph.alignment = textAlignment
        let attr = NSMutableAttributedString(string: raw)
        attr.addAttributes([
            .paragraphStyle: paragraph,
            .font: font as Any,
            .foregroundColor: textColor as Any
        ], range: NSRange(location: 0, length: attr.length))
        attributedText = attr
    }

    /// 链式设置字体。
    ///
    /// - Parameter font: 文本字体。
    /// - Returns: 当前标签实例，便于继续链式调用。
    @discardableResult
    func ba_font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }

    /// 链式设置文字颜色。
    ///
    /// - Parameter color: 文字颜色。
    /// - Returns: 当前标签实例，便于继续链式调用。
    @discardableResult
    func ba_textColor(_ color: UIColor) -> Self {
        textColor = color
        return self
    }

    /// 链式设置文本对齐方式。
    ///
    /// - Parameter alignment: 文本对齐方式。
    /// - Returns: 当前标签实例，便于继续链式调用。
    @discardableResult
    func ba_alignment(_ alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }

    /// 链式设置行数。
    ///
    /// - Parameter lines: 最大显示行数，`0` 表示不限行。
    /// - Returns: 当前标签实例，便于继续链式调用。
    @discardableResult
    func ba_numberOfLines(_ lines: Int) -> Self {
        numberOfLines = lines
        return self
    }

    /// 链式设置文本内容。
    ///
    /// - Parameter text: 文本内容。
    /// - Returns: 当前标签实例，便于继续链式调用。
    @discardableResult
    func ba_text(_ text: String?) -> Self {
        self.text = text
        return self
    }

    /// 高亮指定子串
    func ba_highlight(_ substring: String,
                      color: UIColor,
                      font: UIFont? = nil) {
        guard let raw = text, !raw.isEmpty,
              let range = raw.range(of: substring) else { return }
        let nsRange = NSRange(range, in: raw)
        let attr = NSMutableAttributedString(attributedString:
            attributedText ?? NSAttributedString(string: raw,
                                                 attributes: [.font: self.font as Any,
                                                              .foregroundColor: textColor as Any]))
        attr.addAttribute(.foregroundColor, value: color, range: nsRange)
        if let font = font {
            attr.addAttribute(.font, value: font, range: nsRange)
        }
        attributedText = attr
    }
}
#endif
