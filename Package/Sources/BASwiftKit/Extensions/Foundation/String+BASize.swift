//
//  String+BASize.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation
#if canImport(UIKit)
import UIKit

public extension String {
    /// 按指定字体计算单行文本宽度。
    ///
    /// - Parameter font: 文本字体。
    /// - Returns: 单行文本显示宽度。
    func ba_width(font: UIFont) -> CGFloat {
        let attr = [NSAttributedString.Key.font: font]
        return (self as NSString).size(withAttributes: attr).width
    }

    /// 按指定字体和最大宽度计算多行文本高度。
    ///
    /// - Parameters:
    ///   - font: 文本字体。
    ///   - maxWidth: 文本最大显示宽度。
    /// - Returns: 向上取整后的文本高度。
    func ba_height(font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let bounding = (self as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounding.height)
    }
}
#endif
