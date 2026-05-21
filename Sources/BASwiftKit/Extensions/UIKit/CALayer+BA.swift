//
//  CALayer+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension CALayer {

    /// 开启栅格化（适合复杂阴影 / 圆角的常驻 layer）
    func ba_rasterize() {
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }

    /// 给 layer 加一个柔和 shadow
    func ba_softShadow(color: UIColor = .black,
                       opacity: Float = 0.12,
                       radius: CGFloat = 10,
                       offset: CGSize = CGSize(width: 0, height: 4)) {
        masksToBounds = false
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowRadius = radius
        shadowOffset = offset
    }

    /// 给 layer 加一个 border
    func ba_border(width: CGFloat, color: UIColor) {
        borderWidth = width
        borderColor = color.cgColor
    }
}
#endif
