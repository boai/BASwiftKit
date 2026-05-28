//
//  UIColor+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIColor {

    /// 16 进制串构造（支持 #RGB、#RGBA、#RRGGBB、#RRGGBBAA，前缀可省）
    convenience init?(ba_hex hex: String, alpha: CGFloat = 1.0) {
        var raw = hex.uppercased()
        if raw.hasPrefix("#") { raw.removeFirst() }
        if raw.hasPrefix("0X") { raw.removeFirst(2) }

        // 扩展短格式
        if raw.count == 3 || raw.count == 4 {
            raw = raw.map { "\($0)\($0)" }.joined()
        }

        guard raw.count == 6 || raw.count == 8,
              let value = UInt64(raw, radix: 16) else { return nil }

        let r, g, b, a: CGFloat
        if raw.count == 6 {
            r = CGFloat((value & 0xFF0000) >> 16) / 255.0
            g = CGFloat((value & 0x00FF00) >> 8) / 255.0
            b = CGFloat(value & 0x0000FF) / 255.0
            a = alpha
        } else {
            r = CGFloat((value & 0xFF000000) >> 24) / 255.0
            g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(value & 0x000000FF) / 255.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// 0~255 RGB 便利构造
    static func ba_rgb(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: alpha)
    }

    /// 随机颜色
    static var ba_random: UIColor {
        UIColor(red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1.0)
    }

    /// 适配深浅色。
    static func ba_dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// 转为 16 进制串（#RRGGBB）
    var ba_hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
#endif
