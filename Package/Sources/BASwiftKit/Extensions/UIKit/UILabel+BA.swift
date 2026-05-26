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
